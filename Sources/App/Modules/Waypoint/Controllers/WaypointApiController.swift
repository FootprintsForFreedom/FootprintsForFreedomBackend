//
//  WaypointApiController.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Vapor
import Fluent
import Darwin

extension Waypoint.Waypoint.List: Content { }
extension Waypoint.Waypoint.Detail: Content { }

struct WaypointApiController: ApiController {
    typealias ApiModel = Waypoint.Waypoint
    typealias DatabaseModel = WaypointWaypointModel
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: optional)
        KeyedContentValidator<String>.required("description", optional: optional)
    }
    
    func listOutput(_ req: Request, _ models: Page<WaypointWaypointModel>) async throws -> Page<Waypoint.Waypoint.List> {
        models.map { model in
                .init(
                    id: model.id!,
                    title: model.title.current.value,
                    location: model.location.current.value
                )
        }
    }
    
    func detailOutput(_ req: Request, _ model: WaypointWaypointModel) async throws -> Waypoint.Waypoint.Detail {
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db), user.role >= .moderator {
            return .moderatorDetail(
                id: model.id!,
                title: model.title.current.value,
                description: model.description.current.value,
                location: model.location.current.value,
                verified: model.verified
            )
        }
        return .publicDetail(
            id: model.id!,
            title: model.title.current.value,
            description: model.description.current.value,
            location: model.location.current.value
        )
    }
    
    func createInput(_ req: Request, _ model: WaypointWaypointModel, _ input: Waypoint.Waypoint.Create) async throws {
        model.verified = false
        model.location = try await EditableObjectRepositoryModel.createWith(input.location, on: req.db)
        model.title = try await EditableObjectRepositoryModel.createWith(input.title, on: req.db)
        model.description = try await EditableObjectRepositoryModel.createWith(input.description, on: req.db)
    }
    
    func updateInput(_ req: Request, _ model: WaypointWaypointModel, _ input: Waypoint.Waypoint.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        try await model.location.append(input.location, submittedBy: user.id, on: req)
        try await model.title.append(input.title, submittedBy: user.id, on: req)
        try await model.description.append(input.description, submittedBy: user.id, on: req)
    }
    
    // TODO: make sure cannot delete first entry in ediable text repository since then it would be empty
    // Instead prompt the user to sumbmit a change and verify subsequently
    // but then also remove the previously sumbmitted not verifed text model
    
    func patchInput(_ req: Request, _ model: WaypointWaypointModel, _ input: Waypoint.Waypoint.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        if let newLocation = input.location {
            try await model.location.append(newLocation, submittedBy: user.id, on: req)
        }
        if let newTitle = input.title {
            try await model.title.append(newTitle, submittedBy: user.id, on: req)
        }
        if let newDescription = input.description {
            try await model.description.append(newDescription, submittedBy: user.id, on: req)
        }
    }
}
