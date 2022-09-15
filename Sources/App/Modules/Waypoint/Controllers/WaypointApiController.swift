//
//  WaypointApiController.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

extension Waypoint.Detail.List: Content { }
extension Waypoint.Detail.Detail: Content { }

struct WaypointApiController: ApiRepositoryController {
    typealias ApiModel = Waypoint.Detail
    typealias DatabaseModel = WaypointRepositoryModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: optional)
        KeyedContentValidator<String>.required("detailText", optional: optional)
        KeyedContentValidator<Waypoint.Location>.location("location", optional: optional)
        KeyedContentValidator<String>.required("languageCode", optional: false)
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("detailText")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: true)
        KeyedContentValidator<String>.required("detailText", optional: true)
        KeyedContentValidator<Waypoint.Location>.location("location", optional: true)
        KeyedContentValidator<String>.required("idForWaypointDetailToPatch")

    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("waypoints")
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
    
    // MARK: - List
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<WaypointRepositoryModel>) async throws -> QueryBuilder<WaypointRepositoryModel> {
        queryBuilder
        // also make sure the location is verified
            .join(WaypointLocationModel.self, on: \WaypointLocationModel.$repository.$id == \WaypointRepositoryModel.$id)
            .filter(WaypointLocationModel.self, \.$verifiedAt != nil)
    }
    
    func listOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail) async throws -> Waypoint.Detail.List {
        fatalError()
    }
    
    func listOutput(_ req: Request, _ repositories: Page<WaypointRepositoryModel>) async throws -> Page<Waypoint.Detail.List> {
        // TODO: sort alphabetically
        return try await repositories
            .concurrentCompactMap { repository in
                /// this should not fail since the beforeList only loads repositories which fullfill this criteria
                /// however, to ensure the list works return nil otherwise and use compact map to ensure all other waypoints are returned
                if
                    let detail = try await repository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db),
                    let location = try await repository.$locations.firstFor(needsToBeVerified: true, on: req.db)
                {
                    return try .init(
                        id: repository.requireID(),
                        title: detail.title,
                        slug: detail.slug,
                        location: location.location
                    )
                } else {
                    return nil
                }
            }
    }
    
    // MARK: - Detail
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: WaypointDetailModel) async throws -> Waypoint.Detail.Detail {
        guard let location = try await repository.$locations.firstFor(needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: WaypointDetailModel, _ location: WaypointLocationModel) async throws -> Waypoint.Detail.Detail {
        try await detail.$language.load(on: req.db)
        return try await .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            location: location.location,
            tags: repository.tagList(req),
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(req.db),
            detailId: detail.requireID(),
            locationId: location.requireID()
        )
    }
    
    // MARK: - Create
    
    func createApi(_ req: Request) async throws -> Response {
        let input = try await getCreateInput(req)
        let repository = DatabaseModel()
        try await createRepositoryInput(req, repository, input)
        try await create(req, repository)
        let detail = Detail()
        let location = WaypointLocationModel()
        try await createInput(req, repository, detail, location, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository.$details.create(detail, on: req.db)
        try await repository.$locations.create(location, on: req.db)
        return try await createResponse(req, repository, detail, location)
    }
    
    func beforeCreate(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func createInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail, _ input: Waypoint.Detail.Create) async throws {
        fatalError()
    }
    
    func createInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail, _ location: WaypointLocationModel, _ input: Waypoint.Detail.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        detail.title = input.title
        detail.detailText = input.detailText
        detail.$language.id = languageId
        detail.$user.id = user.id
        
        location.latitude = input.location.latitude
        location.longitude = input.location.longitude
        location.$user.id = user.id
    }
    
    func createResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointDetailModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(status: .created, for: req)
    }
    
    // MARK: - Update
    
    func beforeUpdate(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func updateInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: WaypointDetailModel, _ input: Waypoint.Detail.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        detail.title = input.title
        detail.detailText = input.detailText
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    func updateResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointDetailModel) async throws -> Response {
        guard let location = try await repository.$locations.firstFor(needsToBeVerified: false, on: req.db) else {
            throw Abort(.internalServerError)
        }
        return try await detailOutput(req, repository, waypoint, location).encodeResponse(for: req)
    }
    
    // MARK: - Patch
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        try await beforePatch(req, repository)
        let (detail, location) = try await patchInput(req, repository, input)
        try await afterPatch(req, repository)
        return try await patchResponse(req, repository, detail, location)
    }
    
    func beforePatch(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func patchInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail, _ input: Waypoint.Detail.Patch) async throws {
        fatalError()
    }
    
    func patchInput(_ req: Request, _ repository: WaypointRepositoryModel, _ input: Waypoint.Detail.Patch) async throws -> (WaypointDetailModel, WaypointLocationModel){
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let waypointToPatch = try await WaypointDetailModel.find(input.idForWaypointDetailToPatch, on: req.db) else {
            throw Abort(.badRequest, reason: "No waypoint with the given id could be found")
        }
        
        guard input.title != nil || input.detailText != nil || input.location != nil else {
            throw Abort(.badRequest)
        }
        
        var waypoint: WaypointDetailModel! = nil
        if input.title != nil || input.detailText != nil {
            let newWaypoint = WaypointDetailModel()
            newWaypoint.$user.id = user.id
            newWaypoint.$language.id = waypointToPatch.$language.id
            newWaypoint.title = input.title ?? waypointToPatch.title
            newWaypoint.slug = try await newWaypoint.generateSlug(with: .day, on: req.db)
            newWaypoint.detailText = input.detailText ?? waypointToPatch.detailText
            try await repository.$details.create(newWaypoint, on: req.db)
            waypoint = newWaypoint
        } else {
            waypoint = waypointToPatch
        }
        
        var location: WaypointLocationModel! = nil
        if let inputLocation = input.location {
            let newLocation = try WaypointLocationModel(
                latitude: inputLocation.latitude,
                longitude: inputLocation.longitude,
                repositoryId: repository.requireID(),
                userId: user.id
            )
            try await newLocation.create(on: req.db)
            location = newLocation
        } else {
            guard let storedLocation = try await repository.$locations.firstFor(needsToBeVerified: false, on: req.db) else {
                throw Abort(.internalServerError)
            }
            location = storedLocation
        }
        return (waypoint, location)
    }
    
    func patchResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointDetailModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(for: req)
    }
    
    // MARK: - Delete
    
    // TODO: make sure cannot delete first location or waypoint model since then it would be empty
    // Instead prompt the user to sumbmit a change and verify subsequently
    // but then also remove the previously sumbmitted not verifed text model
    
    // or delte the entire repository when deleting first waypoint
    // TODO: also enable user to delete own waypoint model/location
    // also do that with media
    
    func beforeDelete(_ req: Request, _ repository: WaypointRepositoryModel) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require the user to be an moderator
        guard user.role >= .moderator else {
            throw Abort(.forbidden)
        }
    }
    
    func afterDelete(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        let languageCodes = try await LanguageModel.query(on: req.db).all()
        let elementsToDelete = try languageCodes.map { try ESBulkOperation(operationType: .delete, index: WaypointSummaryModel.Elasticsearch.schema, id: WaypointSummaryModel.Elasticsearch.uniqueId(repositoryId: model.requireID(), languageCode: $0.languageCode), document: WaypointSummaryModel.Elasticsearch.Delete()) }
        let deleteResponse = try req.elastic.bulk(elementsToDelete)
        print(deleteResponse)
    }
}
