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
//            .join(WaypointLocationModel.self, on: \WaypointLocationModel.$repository.$id == \WaypointRepositoryModel.$id)
//            .filter(WaypointLocationModel.self, \.$verified == true)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
//            .sort(WaypointWaypointModel.self, \.$updatedAt, .descending) // newest first
            .sort(WaypointWaypointModel.self, \.$title, .ascending) // from a to z
            .field(\.$id)
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
                        location: .init(latitude: location.latitude, longitude: location.longitude)
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
        
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) {
            
            guard let waypoint = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db) else {
                throw Abort(.notFound)
            }
            // TODO: finish
            try await repository.$locations.load(on: req.db)
            guard let location = repository.locations.first else {
                throw Abort(.internalServerError)
            }
            
            if user.role >= .moderator {
                return try .moderatorDetail(
                    id: repository.id!,
                    title: waypoint.title,
                    description: waypoint.description,
                    location: .init(latitude: location.latitude, longitude: location.longitude),
                    languageCode: waypoint.language.languageCode,
                    verified: waypoint.verified,
                    modelId: waypoint.requireID()
                )
            } else if !waypoint.verified {
                throw Abort(.forbidden)
            }
        }
        guard let waypoint = try await repository.waypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db) else {
            throw Abort(.unauthorized)
        }
        return detailOutput(repository, waypoint)
    }
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel) async throws -> Waypoint.Waypoint.Detail {
//        try await waypoint.load(on: req.db)
        return detailOutput(repository, waypoint)
    }
    
    func detailOutput(_ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel) -> Waypoint.Waypoint.Detail {
        // TODO: finish
        let location = repository.locations.first!
        
        return .publicDetail(
            id: repository.id!,
            title: waypoint.title,
            description: waypoint.description,
            location: .init(latitude: location.latitude, longitude: location.longitude),
            languageCode: waypoint.language.languageCode
        )
    }
    
    func createApi(_ req: Request) async throws -> Response {
        try await RequestValidator(createValidators()).validate(req)
        let input = try req.content.decode(CreateObject.self)
        let model = DatabaseModel()
        try await create(req, model)
        try await createInput(req, model, input)
        return try await createResponse(req, model)
    }
    
    func createInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        let waypoint = try WaypointWaypointModel(
            title: input.title,
            description: input.description,
            languageId: languageId,
            repositoryId: model.requireID(),
            userId: user.id
        )
        let location = try WaypointLocationModel(
            latitude: input.location.latitude,
            longitude: input.location.longitude,
            repositoryId: model.requireID()
        )
        try await waypoint.create(on: req.db)
        try await location.create(on: req.db)
    }
    
    // TODO: dont update location / or store it in repository --> this way it also is the same for all languages
    // mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
    
    func updateApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updateValidators()).validate(req)
        let model = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(UpdateObject.self)
        try await updateInput(req, model, input)
        try await update(req, model)
        return try await updateResponse(req, model)
    }
    
    func updateInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Update) async throws {
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
        
        let waypoint = try WaypointWaypointModel(
            title: input.title,
            description: input.description,
            languageId: languageId,
            repositoryId: model.requireID(),
            userId: user.id
        )
        try await waypoint.create(on: req.db)
    }
    
    func updateResponse(_ req: Request, _ model: WaypointRepositoryModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(status: .created, for: req)
    }
    
    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let model = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        try await patchInput(req, model, input)
        try await patch(req, model)
        return try await patchResponse(req, model)
    }
    
    func patchInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Patch) async throws {
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
        
        
        
        if input.title != nil || input.description != nil || input.location != nil {
            let waypoint = WaypointWaypointModel()
            waypoint.$user.id = user.id
            waypoint.$language.id = languageId
            waypoint.$repository.id = try model.requireID()
            waypoint.verified = false
            
            if let newTitle = input.title, let newDescription = input.description {
                waypoint.title = newTitle
                waypoint.description = newDescription
            } else {
                // TODO: do better query
                guard let latestVerifiedWaypointForPatchLanguage = try await model.waypointModel(for: input.languageCode, needsToBeVerified: true, on: req.db) else {
                    throw Abort(.badRequest)
                }
                
                waypoint.title = input.title ?? latestVerifiedWaypointForPatchLanguage.title
                waypoint.description = input.description ?? latestVerifiedWaypointForPatchLanguage.description
            }
            try await waypoint.create(on: req.db)
        }
        
        if let location = input.location {
            let location = try WaypointLocationModel(
                latitude: location.latitude,
                longitude: location.longitude,
                repositoryId: model.requireID()
            )
            try await location.create(on: req.db)
        }
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
