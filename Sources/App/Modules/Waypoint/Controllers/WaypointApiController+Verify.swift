//
//  WaypointApiController+Verify.swift
//  
//
//  Created by niklhut on 01.03.22.
//

import Vapor
import Fluent
import SwiftDiff
import ElasticsearchNIOClient

extension Waypoint.Repository.Changes: Content { }

extension WaypointApiController: ApiRepositoryVerificationController {
    
    // MARK: - detail changes
    
    func beforeDetailChanges(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$user)
    }
    
    // GET: api/waypoints/:repositoryID/waypoints/changes/?from=model1ID&to=model2ID
    func detailChangesOutput(_ req: Request, _ model1: Detail, _ model2: Detail) async throws -> Waypoint.Repository.Changes {
        /// compute the diffs
        let titleDiff = diff(text1: model1.title, text2: model2.title).cleaningUpSemantics()
        let detailTextDiff = diff(text1: model1.detailText, text2: model2.detailText).cleaningUpSemantics()
        
        return try .init(
            titleDiff: titleDiff,
            detailTextDiff: detailTextDiff,
            fromUser: model1.user?.publicDetail(),
            toUser: model2.user?.publicDetail()
        )
    }
    
    func setupDetailChangesRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes
            .grouped("waypoints")
            .get("changes", use: detailChangesApi)
    }
    
    // MARK: - list repositories with unverified details
    
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetRepositories(_ req: Request, _ queryBuilder: QueryBuilder<WaypointRepositoryModel>) async throws -> QueryBuilder<WaypointRepositoryModel> {
        queryBuilder
            .join(children: \.$details)
            .join(children: \.$locations)
            .join(from: Detail.self, parent: \.$language)
            .join(children: \.$tags.$pivots, method: .left)
            .group(.or) {
                $0
                // only get unverified locations
                    .filter(WaypointLocationModel.self, \.$verifiedAt == nil)
                    .group(.and) {
                        $0
                        // only get unverified details
                            .filter(WaypointDetailModel.self, \.$verifiedAt == nil)
                        // only select details which have an active language
                            .filter(LanguageModel.self, \.$priority != nil)
                    }
                    .filter(WaypointTagModel.self, \.$status ~~ [.pending, .deleteRequested])
            }
        // only select the id field and return each id only once
            .field(\.$id)
            .unique()
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail) async throws -> Waypoint.Detail.List {
        guard let location = try await repository.$locations.firstFor(needsToBeVerified: false, on: req.db) else {
            throw Abort(.internalServerError)
        }
        
        return try .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            location: location.location
        )
    }
    
    // MARK: - list unverified details for repository
    
    func beforeListUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetUnverifiedDetail(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$language)
    }
    
    // GET: api/waypoints/:repositoryId/waypoints/unverified
    func listUnverifiedDetailsOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail) async throws -> Waypoint.Repository.ListUnverifiedWaypoints {
        return try .init(
            detailId: detail.requireID(),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            languageCode: detail.language.languageCode
        )
    }
    
    func setupListUnverifiedDetailsRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes
            .grouped("waypoints")
            .get("unverified", use: listUnverifiedDetailsApi)
    }
    
    // MARK: - list unverified locations
    
    // GET: api/waypoints/:repositoryId/locations/unverified
    func listUnverifiedLocations(_ req: Request) async throws -> Page<Waypoint.Repository.ListUnverifiedLocations> {
        try await req.onlyFor(.moderator)
        
        let repository = try await repository(req)
        
        let unverifiedLocations = try await repository.$locations
            .query(on: req.db)
            .filter(\.$verifiedAt == nil)
            .sort(\.$updatedAt, .ascending) // oldest first
            .paginate(for: req)
        
        return try unverifiedLocations.map { location in
            return try .init(
                locationId: location.requireID(),
                location: location.location
            )
        }
    }
    
    // MARK: - verify detail
    
    func beforeVerifyDetail(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func afterVerifyDetail(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail) async throws {
        try await WaypointSummaryModel.Elasticsearch.createOrUpdate(detailWithId: detail.requireID(), on: req)
    }
    
    // POST: api/waypoints/:repositoryId/waypoints/verify/:waypointModelId
    func verifyDetailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail) async throws -> Waypoint.Detail.Detail {
        guard let location = try await repository.$locations.firstFor(needsToBeVerified: false, on: req.db) else {
            throw Abort(.internalServerError)
        }
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    func setupVerifyDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes
            .grouped("waypoints")
            .grouped("verify")
            .grouped(newModelPathIdComponent)
            .post(use: verifyDetailApi)
    }
    
    // MARK: - verify location
    
    // POST: api/waypoints/:repositoryId/locations/verify/:waypointModelId
    func verifyLocation(_ req: Request) async throws -> Waypoint.Detail.Detail {
        try await req.onlyFor(.moderator)
        
        let repository = try await repository(req)
        guard
            let locationIdString = req.parameters.get(newModelPathIdKey),
            let locationId = UUID(uuidString: locationIdString)
        else {
            throw Abort(.badRequest)
        }
        
        guard let location = try await WaypointLocationModel
            .query(on: req.db)
            .filter(\._$id == locationId)
            .filter(\.$repository.$id == repository.requireID())
            .filter(\.$verifiedAt == nil)
            .first()
        else {
            throw Abort(.badRequest)
        }
        location.verifiedAt = Date()
        try await location.update(on: req.db)
        
        try await WaypointSummaryModel.Elasticsearch.createOrUpdate(detailsWithRepositoryId: repository.requireID(), on: req)
        
        let allLanguageCodesByPriority = try await req.allLanguageCodesByPriority()
        
        guard let detail = try await repository._$details.firstFor(allLanguageCodesByPriority, needsToBeVerified: false, on: req.db) else {
            throw Abort(.internalServerError)
        }
        try await detail.$language.load(on: req.db)
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    // MARK: - routes
    
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        setupDetailChangesRoutes(routes)
        setupListRepositoriesWithUnverifiedDetailsRoutes(routes)
        setupListUnverifiedDetailsRoutes(routes)
        setupVerifyDetailRoutes(routes)
        
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        let locationRoutes = existingModelRoutes.grouped("locations")
        locationRoutes.get("unverified", use: listUnverifiedLocations)
        locationRoutes.grouped("verify")
            .grouped(newModelPathIdComponent)
            .post(use: verifyLocation)
    }
}

