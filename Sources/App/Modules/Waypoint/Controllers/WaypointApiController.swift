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
    }
    
    // TODO: verification route
    
    func listOutput(_ req: Request, _ models: Page<WaypointRepositoryModel>) async throws -> Page<Waypoint.Waypoint.List> {
        try await models
            .compactMap {
                $0.verified ? $0 : nil
            }
            .concurrentMap { model in
                try await model.currentProperty.load(on: req.db)
                try await model.current.loadTitle(on: req.db)
                try await model.current.loadLocation(on: req.db)
                return .init(
                    id: model.id!,
                    title: model.current.title.value,
                    location: model.current.location.value
                )
            }
    }
    
    func detailOutput(_ req: Request, _ model: WaypointRepositoryModel) async throws -> Waypoint.Waypoint.Detail {
        try await model.currentProperty.load(on: req.db)
        try await model.current.load(on: req.db)
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) {
            if user.role >= .moderator {
                return .moderatorDetail(
                    id: model.id!,
                    title: model.current.title.value,
                    description: model.current.description.value,
                    location: model.current.location.value,
                    verified: model.verified
                )
            } else if req.method == .POST || req.method == .PUT || req.method == .PATCH {
                /// return public detail after create, update or patch regardless of model verification
                return .publicDetail(
                    id: model.id!,
                    title: model.current.title.value,
                    description: model.current.description.value,
                    location: model.current.location.value
                )
            } else if !model.verified {
                throw Abort(.forbidden)
            }
        }
        guard model.verified else {
            throw Abort(.unauthorized)
        }
        return .publicDetail(
            id: model.id!,
            title: model.current.title.value,
            description: model.current.description.value,
            location: model.current.location.value
        )
    }
    
    func createInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        let waypointModel = try await WaypointWaypointModel.createWith(title: input.title, description: input.description, location: input.location, userId: user.id, on: req.db)
        model.verified = false
        model.currentProperty.id = try waypointModel.requireID()
        model.lastProperty.id = try waypointModel.requireID()
    }
    
    func updateInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        try await model.currentProperty.load(on: req.db)
        
        let newTitle = try await model.current.append(\.$title, input.title, on: req)
        let newDescription = try await model.current.append(\.$description, input.description, on: req)
        let newLocation = try await model.current.append(\.$location, input.location, on: req)
        
        let newWaypointModel = try WaypointWaypointModel(
            titleId: newTitle.requireID(),
            descriptionId: newDescription.requireID(),
            locationId: newLocation.requireID(),
            userId: user.id
        )
        try await model.append(newWaypointModel, on: req)
    }
    
    // TODO: make sure cannot delete first entry in ediable text repository since then it would be empty
    // Instead prompt the user to sumbmit a change and verify subsequently
    // but then also remove the previously sumbmitted not verifed text model
    
    func patchInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        try await model.currentProperty.load(on: req.db)
        
        var patchedTitle: EditableObjectModel<String>?
        var patchedDesctiption: EditableObjectModel<String>?
        var patchedLocation: EditableObjectModel<Waypoint.Location>?
        
        if let newTitle = input.title {
            patchedTitle = try await model.current.append(\.$title, newTitle, on: req)
        }
        if let newDescription = input.description {
            patchedDesctiption = try await model.current.append(\.$description, newDescription, on: req)
        }
        if let newLocation = input.location {
            patchedLocation = try await model.current.append(\.$location, newLocation, on: req)
        }
        
        /// only create a new waypoint model if something changed
        if patchedTitle != nil || patchedDesctiption != nil || patchedLocation != nil {
            let newWaypointModel = try WaypointWaypointModel(
                titleId: patchedTitle?.requireID() ?? model.current.$title.id,
                descriptionId: patchedDesctiption?.requireID() ?? model.current.$description.id,
                locationId: patchedLocation?.requireID() ?? model.current.$location.id,
                userId: user.id
            )
            try await model.append(newWaypointModel, on: req)
        }
    }
    
    func beforeDelete(_ req: Request, _ model: WaypointRepositoryModel) async throws {
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
        try await model.load(on: req.db)
        try await model.current.load(on: req.db)
        try await model.current.title.deleteAll(on: req.db)
        try await model.current.description.deleteAll(on: req.db)
        try await model.current.location.deleteAll(on: req.db)
        //        try await model.removeAll(on: req)
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
