//
//  WaypointApiController.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Vapor
import Fluent

extension Waypoint.Waypoint.List: Content { }
extension Waypoint.Waypoint.Detail: Content { }

struct WaypointApiController: ApiController {
    typealias ApiModel = Waypoint.Waypoint
    typealias DatabaseModel = WaypointRepositoryModel
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("waypoints")
    }
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: optional)
        KeyedContentValidator<String>.required("description", optional: optional)
        KeyedContentValidator<Waypoint.Location>.location("location", optional: optional)
        KeyedContentValidator<String>.required("languageCode", optional: false)
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("description")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    struct PreferredLanguageQuery: Codable {
        let preferredLanguage: String?
    }
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<WaypointRepositoryModel>) async throws -> QueryBuilder<WaypointRepositoryModel> {
        queryBuilder
            .join(WaypointWaypointModel.self, on: \WaypointWaypointModel.$repository.$id == \WaypointRepositoryModel.$id)
            .filter(WaypointWaypointModel.self, \.$verified == true)
            .join(WaypointLocationModel.self, on: \WaypointLocationModel.$repository.$id == \WaypointRepositoryModel.$id)
            .filter(WaypointLocationModel.self, \.$verified == true)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
        //            .sort(WaypointWaypointModel.self, \.$updatedAt, .descending) // newest first
        //            .sort(WaypointWaypointModel.self, \.$title, .ascending) // from a to z
            .field(\.$id)
            .unique()
    }
    
    func listOutput(_ req: Request, _ models: Page<WaypointRepositoryModel>) async throws -> Page<Waypoint.Waypoint.List> {
        // TODO: sort alphabetically
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        return try await models
            .concurrentMap { model in
                /// this should not fail since the beforeList only loads repositories which fullfill this criteria
                /// however, to ensure the list works return nil otherwise and use compact map to ensure all other waypoints are returned
                if
                    let waypoint = try await model.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db),
                    // TODO: make verified true
                    let location = try await model.location(needsToBeVerified: false, on: req.db)
                {
                    return try .init(
                        id: model.requireID(),
                        title: waypoint.title,
                        location: location.location
                    )
                } else {
                    return nil
                }
            }
            .compactMap { $0 }
    }
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel) async throws -> Waypoint.Waypoint.Detail {
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        guard
            let waypoint = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db),
            let location = try await repository.location(needsToBeVerified: true, on: req.db)
        else {
            throw Abort(.notFound)
        }
        try await waypoint.$language.load(on: req.db)
        
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db), user.role >= .moderator {
            return try .moderatorDetail(
                id: repository.id!,
                title: waypoint.title,
                description: waypoint.description,
                location: location.location,
                languageCode: waypoint.language.languageCode,
                verified: waypoint.verified && location.verified,
                modelId: waypoint.requireID(),
                locationId: location.requireID()
            )
        }
        return try await detailOutput(req, repository, waypoint, location)
    }
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ location: WaypointLocationModel) async throws -> Waypoint.Waypoint.Detail {
        try await waypoint.$language.load(on: req.db)
        return .publicDetail(
            id: repository.id!,
            title: waypoint.title,
            description: waypoint.description,
            location: location.location,
            languageCode: waypoint.language.languageCode
        )
    }
    
    func createApi(_ req: Request) async throws -> Response {
        try await RequestValidator(createValidators()).validate(req)
        let input = try req.content.decode(CreateObject.self)
        let repository = DatabaseModel()
        try await create(req, repository)
        let waypoint = WaypointWaypointModel()
        let location = WaypointLocationModel()
        try await createInput(req, repository, waypoint, location, input)
        try await waypoint.create(on: req.db)
        try await location.create(on: req.db)
        return try await createResponse(req, repository, waypoint, location)
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func createInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Create) async throws {
        fatalError()
    }
    
    func createInput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ location: WaypointLocationModel, _ input: Waypoint.Waypoint.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        waypoint.verified = false
        waypoint.title = input.title
        waypoint.description = input.description
        waypoint.$language.id = languageId
        waypoint.$repository.id = try repository.requireID()
        waypoint.$user.id = user.id
        
        location.verified = false
        location.latitude = input.location.latitude
        location.longitude = input.location.longitude
        location.$repository.id = try repository.requireID()
        location.$user.id = user.id
    }
    
    func createResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(status: .created, for: req)
    }
    
    // TODO: dont update location / or store it in repository --> this way it also is the same for all languages
    // mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
    
    func updateApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updateValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(UpdateObject.self)
        let waypoint = WaypointWaypointModel()
        try await updateInput(req, repository, waypoint, input)
        try await waypoint.create(on: req.db)
        let latestVerifiedLocation = try await repository.location(needsToBeVerified: true, on: req.db)
        var location: WaypointLocationModel! = latestVerifiedLocation
        if location == nil {
            guard let oldestLocation = try await repository.location(needsToBeVerified: false, on: req.db) else {
                throw Abort(.internalServerError)
            }
            location = oldestLocation
        }
        return try await updateResponse(req, repository, waypoint, location)
    }
    
    func updateInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Update) async throws {
        fatalError()
    }
    
    
    func updateInput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ input: Waypoint.Waypoint.Update) async throws {
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
        
        waypoint.verified = false
        waypoint.title = input.title
        waypoint.description = input.description
        waypoint.$language.id = languageId
        waypoint.$repository.id = try repository.requireID()
        waypoint.$user.id = user.id
    }
    
    func updateResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(for: req)
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        let (waypoint, location) = try await patchInput(req, repository, input)
        return try await patchResponse(req, repository, waypoint, location)
    }
    
    func patchInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Patch) async throws {
        fatalError()
    }
    
    func patchInput(_ req: Request, _ repository: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Patch) async throws -> (WaypointWaypointModel, WaypointLocationModel){
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let language = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()
        else {
            throw Abort(.badRequest)
        }
        
        var waypoint: WaypointWaypointModel! = nil
        if input.title != nil || input.description != nil || input.location != nil {
            let newWaypoint = WaypointWaypointModel()
            newWaypoint.verified = false
            newWaypoint.$user.id = user.id
            newWaypoint.$language.id = try language.requireID()
            newWaypoint.$repository.id = try repository.requireID()
            
            if let newTitle = input.title, let newDescription = input.description {
                newWaypoint.title = newTitle
                newWaypoint.description = newDescription
            } else {
                // TODO: do better query
                guard let latestVerifiedWaypointForPatchLanguage = try await repository.waypointModel(for: input.languageCode, needsToBeVerified: true, on: req.db) else {
                    throw Abort(.badRequest)
                }
                
                newWaypoint.title = input.title ?? latestVerifiedWaypointForPatchLanguage.title
                newWaypoint.description = input.description ?? latestVerifiedWaypointForPatchLanguage.description
            }
            try await newWaypoint.create(on: req.db)
            waypoint = newWaypoint
        } else {
            guard let latestVerifiedWaypointForPatchLanguage = try await repository.waypointModel(for: language.languageCode, needsToBeVerified: true, on: req.db) else {
                throw Abort(.badRequest)
            }
            waypoint = latestVerifiedWaypointForPatchLanguage
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
            let latestVerifiedLocation = try await repository.location(needsToBeVerified: true, on: req.db)
            location = latestVerifiedLocation
            if location == nil {
                guard let oldestLocation = try await repository.location(needsToBeVerified: false, on: req.db) else {
                    throw Abort(.internalServerError)
                }
                location = oldestLocation
            }
        }
        return (waypoint, location)
    }
    
    func patchResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(for: req)
    }
    
    // TODO: make sure cannot delete first location or waypoint model since then it would be empty
    // Instead prompt the user to sumbmit a change and verify subsequently
    // but then also remove the previously sumbmitted not verifed text model
    
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
        // TODO: test deletes locations and models
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
}
