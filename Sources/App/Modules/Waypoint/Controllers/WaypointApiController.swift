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

struct WaypointApiController: ApiRepositoryController {
    typealias ApiModel = Waypoint.Waypoint
    typealias DatabaseModel = WaypointRepositoryModel
    typealias ObjectModel = WaypointWaypointModel
    
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
    
    struct PreferredLanguageQuery: Codable {
        let preferredLanguage: String?
    }
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<WaypointRepositoryModel>) async throws -> QueryBuilder<WaypointRepositoryModel> {
        queryBuilder
            .join(WaypointWaypointModel.self, on: \WaypointWaypointModel.$repository.$id == \WaypointRepositoryModel.$id)
            .filter(WaypointWaypointModel.self, \.$verified == true)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
            .field(\.$id)
            .unique()
    }
    
    func listOutput(_ req: Request, _ models: Page<WaypointRepositoryModel>) async throws -> Page<Waypoint.Waypoint.List> {
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        return try await models
            .concurrentMap { model in
                /// this should not fail since the beforeList only loads repositories which fullfill this criteria
                /// however, to ensure the list works return nil otherwise and use compact map to ensure all other waypoints are returned
                if let waypoint = try await model.latestWaypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db, loadDescription: false) {
                    return try .init(
                        id: model.requireID(),
                        title: waypoint.title.value,
                        location: waypoint.location.value
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
            
            guard let waypoint = try await repository.latestWaypointModel(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db, loadDescription: true) else {
                throw Abort(.notFound)
            }
            
            if user.role >= .moderator {
                return try .moderatorDetail(
                    id: repository.id!,
                    title: waypoint.title.value,
                    description: waypoint.description.value,
                    location: waypoint.location.value,
                    languageCode: waypoint.language.languageCode,
                    verified: waypoint.verified,
                    modelId: waypoint.requireID()
                )
            } else if !waypoint.verified {
                throw Abort(.forbidden)
            }
        }
        guard let waypoint = try await repository.latestWaypointModel(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db, loadDescription: true) else {
            throw Abort(.unauthorized)
        }
        return detailOutput(repository, waypoint)
    }
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel) async throws -> Waypoint.Waypoint.Detail {
        try await waypoint.load(on: req.db)
        return detailOutput(repository, waypoint)
    }
    
    func detailOutput(_ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel) -> Waypoint.Waypoint.Detail {
        return .publicDetail(
            id: repository.id!,
            title: waypoint.title.value,
            description: waypoint.description.value,
            location: waypoint.location.value,
            languageCode: waypoint.language.languageCode
        )
    }
    
    func createInput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ input: Waypoint.Waypoint.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == input.languageCode)
                .first()?
                .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        try await waypoint.with(
            title: input.title,
            description: input.description,
            location: input.location,
            repositoryId: repository.requireID(),
            languageId: languageId,
            userId: user.id,
            verified: false,
            on: req.db
        )
    }
    
    // TODO: dont update location / or store it in repository --> this way it also is the same for all languages
    // mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
    
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
        
        try await waypoint.with(
            title: input.title,
            description: input.description,
            location: input.location,
            repositoryId: repository.requireID(),
            languageId: languageId,
            userId: user.id,
            verified: false,
            on: req.db
        )
    }
    
    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func patchInput(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointWaypointModel, _ input: Waypoint.Waypoint.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        waypoint.$user.id = user.id
        
        if input.title == nil && input.description == nil && input.location == nil {
            throw Abort(.badRequest)
        }
        
        guard let languageId = try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == input.languageCode)
                .first()?
                .requireID()
        else {
            throw Abort(.badRequest)
        }
        waypoint.$language.id = languageId
        
        if let newTitle = input.title, let newDescription = input.description, let newLocation = input.location {
            try await waypoint.set(\.$title, to: newTitle, user.id, on: req.db)
            try await waypoint.set(\.$description, to: newDescription, user.id, on: req.db)
            try await waypoint.set(\.$location, to: newLocation, user.id, on: req.db)
        } else {
            guard let latestVerifiedWaypointForPatchLanguage = try await repository.latestWaypointModel(for: input.languageCode, needsToBeVerified: true, on: req.db, loadDescription: false) else {
                throw Abort(.badRequest)
            }
            try await latestVerifiedWaypointForPatchLanguage.load(on: req.db)
            
            if let newTitle = input.title {
                try await waypoint.set(\.$title, to: newTitle, user.id, on: req.db)
            } else {
                waypoint.$title.id = try latestVerifiedWaypointForPatchLanguage.title.requireID()
            }
            
            if let newDescription = input.description {
                try await waypoint.set(\.$description, to: newDescription, user.id, on: req.db)
            } else {
                waypoint.$description.id = try latestVerifiedWaypointForPatchLanguage.description.requireID()
            }
            
            if let newLocation = input.location {
                try await waypoint.set(\.$location, to: newLocation, user.id, on: req.db)
            } else {
                waypoint.$location.id = try latestVerifiedWaypointForPatchLanguage.location.requireID()
            }
        }
        
        waypoint.$repository.id = try repository.requireID()
        waypoint.verified = false
    }
    
    // TODO: make sure cannot delete first entry in ediable text repository since then it would be empty
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
        
        /// delete the associated models
        try await repository.$waypoints.load(on: req.db)
        for waypoint in repository.waypoints {
            try await waypoint.load(on: req.db)
            try await waypoint.title.delete(on: req.db)
            try await waypoint.description.delete(on: req.db)
            try await waypoint.location.delete(on: req.db)
        }
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
