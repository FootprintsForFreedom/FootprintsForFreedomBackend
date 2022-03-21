//
//  WaypointApiController+Verify.swift
//  
//
//  Created by niklhut on 01.03.22.
//

import Vapor
import Fluent
import DiffMatchPatch

extension Waypoint.Repository.Changes: Content { }

extension WaypointApiController {
    func onlyForModerator(_ req: Request) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a admin or higher
        guard user.role >= .moderator else {
            throw Abort(.forbidden)
        }
    }
    
    // GET: api/wayponts/:repositoryID/waypoints/changes/?from=model1ID&to=model2ID
    func detailChanges(_ req: Request) async throws -> Waypoint.Repository.Changes {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
        let detailChangesRequest = try req.query.decode(Waypoint.Repository.DetailChangesRequest.self)
        
        guard let fromId = detailChangesRequest.from,
              let toId = detailChangesRequest.to
        else {
            throw Abort(.badRequest)
        }
        
        guard let model1 = try await WaypointWaypointModel
                .query(on: req.db)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\._$id == fromId)
                .with(\.$user)
                .first(),
              let model2 = try await WaypointWaypointModel
                .query(on: req.db)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\._$id == toId)
                .with(\.$user)
                .first()
        else {
            throw Abort(.notFound)
        }
        
        guard model1.$language.id == model2.$language.id else {
            throw Abort(.badRequest, reason: "The models need to be of the same language")
        }
        
        /// compute the diffs
        let titleDiff = computeDiff(model1.title, model2.title)
            .cleaningUpSemantics()
            .converted()
        let descriptionDiff = computeDiff(model1.description, model2.description)
            .cleaningUpSemantics()
            .converted()
        
        let model1User = try User.Account.Detail.publicDetail(id: model1.user.requireID(), name: model1.user.name, school: model1.user.school)
        let model2User = try User.Account.Detail.publicDetail(id: model2.user.requireID(), name: model2.user.name, school: model2.user.school)
        return .init(
            titleDiff: titleDiff,
            descriptionDiff: descriptionDiff,
            fromUser: model1User,
            toUser: model2User
        )
    }
    
    // Returns all repositories with unverified waypoint or location models
    func listRepositoriesWithUnverifiedModels(_ req: Request) async throws -> Page<Waypoint.Waypoint.List> {
        try await onlyForModerator(req)
        
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        let repositoriesWithUnverifiedModels = try await WaypointRepositoryModel
            .query(on: req.db)
            .join(WaypointWaypointModel.self, on: \WaypointWaypointModel.$repository.$id == \WaypointRepositoryModel.$id)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .join(WaypointLocationModel.self, on: \WaypointLocationModel.$repository.$id == \WaypointRepositoryModel.$id)
            .group(.or) { group in
                group.filter(WaypointLocationModel.self, \.$verified == false)
                    .group(.and) { group2 in
                        group2.filter(WaypointWaypointModel.self, \.$verified == false)
                            .filter(LanguageModel.self, \.$priority != nil)
                    }
            }
            .field(\.$id)
            .paginate(for: req)
        
        return try await repositoriesWithUnverifiedModels.concurrentMap { repository in
            let latestVerifiedWaypointModel = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db, sort: .ascending)
            var waypointModel: WaypointWaypointModel! = latestVerifiedWaypointModel
            if waypointModel == nil {
                guard let oldestWaypointModel = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db, sort: .ascending) else {
                    throw Abort(.internalServerError)
                }
                waypointModel = oldestWaypointModel
            }
            
            let latestVerifiedLocation = try await repository.location(needsToBeVerified: true, on: req.db)
            var location: WaypointLocationModel! = latestVerifiedLocation
            if location == nil {
                guard let oldestLocation = try await repository.location(needsToBeVerified: false, on: req.db) else {
                    throw Abort(.internalServerError)
                }
                location = oldestLocation
            }
            
            return try .init(
                id: repository.requireID(),
                title: waypointModel.title,
                location: .init(latitude: location.latitude, longitude: location.longitude)
            )
        }
    }
    
    // GET: api/waypoints/:repositoryId/waypoints/unverified
    func listUnverifiedWaypoints(_ req: Request) async throws -> Page<Waypoint.Repository.ListUnverifiedWaypoints> {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
        
        let unverifiedWaypoints = try await repository.$waypoints
            .query(on: req.db)
            .filter(\.$verified == false)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
            .sort(\.$updatedAt, .ascending) // oldest first
            .with(\.$language)
            .paginate(for: req)
        
        return try unverifiedWaypoints.map { waypoint in
            return try .init(
                modelId: waypoint.requireID(),
                title: waypoint.title,
                description: waypoint.description,
                languageCode: waypoint.language.languageCode
            )
        }
    }
    
    // GET: api/waypoints/:repositoryId/locations/unverified
    func listUnverifiedLocations(_ req: Request) async throws -> Page<Waypoint.Repository.ListUnverifiedLocations> {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
        
        let unverifiedLocations = try await repository.$locations
            .query(on: req.db)
            .filter(\.$verified == false)
            .sort(\.$updatedAt, .ascending) // oldest first
            .paginate(for: req)
        
        return try unverifiedLocations.map { location in
            return try .init(
                locationId: location.requireID(),
                location: .init(latitude: location.latitude, longitude: location.longitude)
            )
        }
    }
    
    var newModelPathIdKey: String { "newModel" }
    var newModelPathIdComponent: PathComponent { .init(stringLiteral: ":" + newModelPathIdKey) }
    
    // POST: api/waypoints/:repositoryId/waypoints/verify/:waypointModelId
    func verifyWaypoint(_ req: Request) async throws -> Waypoint.Waypoint.Detail {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
        guard
            let waypointIdString = req.parameters.get(newModelPathIdKey),
            let waypointId = UUID(uuidString: waypointIdString)
        else {
            throw Abort(.badRequest)
        }
        
        guard let waypoint = try await WaypointWaypointModel
                .query(on: req.db)
                .filter(\._$id == waypointId)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\.$verified == false)
                .with(\.$language)
                .first()
        else {
            throw Abort(.badRequest)
        }
        waypoint.verified = true
        try await waypoint.update(on: req.db)
        
        let latestVerifiedLocation = try await repository.location(needsToBeVerified: true, on: req.db)
        var location: WaypointLocationModel! = latestVerifiedLocation
        if location == nil {
            guard let oldestLocation = try await repository.location(needsToBeVerified: false, on: req.db) else {
                throw Abort(.internalServerError)
            }
            location = oldestLocation
        }
        
        return try .moderatorDetail(
            id: repository.id!,
            title: waypoint.title,
            description: waypoint.description,
            location: .init(latitude: location.latitude, longitude: location.longitude),
            languageCode: waypoint.language.languageCode,
            verified: waypoint.verified,
            modelId: waypoint.requireID(),
            locationId: location.requireID()
        )
    }
    
    // POST: api/waypoints/:repositoryId/locations/verify/:waypointModelId
    func verifyLocation(_ req: Request) async throws -> Waypoint.Waypoint.Detail {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
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
                .filter(\.$verified == false)
                .first()
        else {
            throw Abort(.badRequest)
        }
        location.verified = true
        try await location.update(on: req.db)
        
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        let latestVerifiedWaypointModel = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db, sort: .ascending)
        var waypoint: WaypointWaypointModel! = latestVerifiedWaypointModel
        if waypoint == nil {
            guard let oldestWaypointModel = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db, sort: .ascending) else {
                throw Abort(.internalServerError)
            }
            waypoint = oldestWaypointModel
        }
        
        return try .moderatorDetail(
            id: repository.id!,
            title: waypoint.title,
            description: waypoint.description,
            location: .init(latitude: location.latitude, longitude: location.longitude),
            languageCode: waypoint.language.languageCode,
            verified: waypoint.verified,
            modelId: waypoint.requireID(),
            locationId: location.requireID()
        )
    }
    
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("unverified", use: listRepositoriesWithUnverifiedModels)
        
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        let waypointRoutes = existingModelRoutes.grouped("waypoints")
        waypointRoutes.get("unverified", use: listUnverifiedWaypoints)
        waypointRoutes.get("changes", use: detailChanges)
        waypointRoutes.grouped("verify")
            .grouped(newModelPathIdComponent)
            .post(use: verifyWaypoint)
        
        let locationRoutes = existingModelRoutes.grouped("locations")
        locationRoutes.get("unverified", use: listUnverifiedLocations)
        locationRoutes.grouped("verify")
            .grouped(newModelPathIdComponent)
            .post(use: verifyLocation)
    }
}

