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
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db), user.role >= .moderator {
            return .moderatorDetail(
                id: model.id!,
                title: model.current.title.value,
                description: model.current.description.value,
                location: model.current.location.value,
                verified: model.verified
            )
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
        
        let newTitle = try await model.current.append(\.title, input.title, on: req)
        let newDescription = try await model.current.append(\.description, input.description, on: req)
        let newLocation = try await model.current.append(\.location, input.location, on: req)
        
        let newWaypointModel = try WaypointWaypointModel(
            titleId: newTitle.requireID(),
            descriptionId: newDescription.requireID(),
            locationId: newLocation.requireID(),
            userId: user.id)
        try await model.append(newWaypointModel, on: req)
    }
    
    // TODO: make sure cannot delete first entry in ediable text repository since then it would be empty
    // Instead prompt the user to sumbmit a change and verify subsequently
    // but then also remove the previously sumbmitted not verifed text model
    
    func patchInput(_ req: Request, _ model: WaypointRepositoryModel, _ input: Waypoint.Waypoint.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
//        if let newTitle = input.title {
//            try await model.title.append(newTitle, submittedBy: user.id, on: req)
//        }
//        if let newDescription = input.description {
//            try await model.description.append(newDescription, submittedBy: user.id, on: req)
//        }
//        if let newLocation = input.location {
//            try await model.location.append(newLocation, submittedBy: user.id, on: req)
//        }
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
