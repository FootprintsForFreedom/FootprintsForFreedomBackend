//
//  WaypointWaypointModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class WaypointWaypointModel: NodeModel {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var locationId: FieldKey { "location_id" }
            static var titleId: FieldKey { "title_id" }
            static var descriptionId: FieldKey { "description_id" }
            static var previousId: FieldKey { "previous_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    
    @Parent(key: FieldKeys.v1.titleId) var title: EditableObjectModel<String>
    @Parent(key: FieldKeys.v1.descriptionId) var description: EditableObjectModel<String>
    @Parent(key: FieldKeys.v1.locationId) var location: EditableObjectModel<Waypoint.Location>
    
    @Children(for: \.$waypoint) var media: [WaypointMediaModel]
    
    // TODO: likes as sibling?
    
    @OptionalChild(for: \.$previous) var next: WaypointWaypointModel?
    @OptionalParent(key: FieldKeys.v1.previousId) var previous: WaypointWaypointModel?
    
    var nextProperty: OptionalChildProperty<WaypointWaypointModel, WaypointWaypointModel> { $next }
    var previousProperty: OptionalParentProperty<WaypointWaypointModel, WaypointWaypointModel> { $previous }
    
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        titleId: UUID,
        descriptionId: UUID,
        locationId: UUID,
        previousId: UUID? = nil,
        userId: UUID
    ) {
        self.id = id
        self.$title.id = titleId
        self.$description.id = descriptionId
        self.$location.id = locationId
        self.$previous.id = previousId
        self.$user.id = userId
    }
}

extension WaypointWaypointModel: Equatable {
    static func == (lhs: WaypointWaypointModel, rhs: WaypointWaypointModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension WaypointWaypointModel {
    func last<NodeObject: NodeModel>(for keyPath: KeyPath<WaypointWaypointModel, NodeObject>, on db: Database) async throws -> NodeObject {
        var node = self[keyPath: keyPath]
        try await node.nextProperty.load(on: db)
        while let nextNode = node.next {
            try await nextNode.nextProperty.load(on: db)
            node = nextNode
        }
        return node
    }
    
    func append<T>(_ keyPath: KeyPath<WaypointWaypointModel, EditableObjectModel<T>>, _ newValue: T, on req: Request) async throws -> EditableObjectModel<T> {
        let user = try req.auth.require(AuthenticatedUser.self)
        let lastNode = try await last(for: keyPath, on: req.db)
        let newNode = EditableObjectModel<T>(value: newValue, userId: user.id)
        try await lastNode.$next.create(lastNode, on: req.db)
        return newNode
    }
}

extension WaypointWaypointModel {
    static func createWith(
        title: String,
        description: String,
        location: Waypoint.Location,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let title = EditableObjectModel<String>(value: title, userId: userId)
        try await title.create(on: db)
        let description = EditableObjectModel<String>(value: description, userId: userId)
        try await description.create(on: db)
        let location = EditableObjectModel<Waypoint.Location>(value: location, userId: userId)
        try await location.create(on: db)
        
        let waypoint = try self.init(
            titleId: title.requireID(),
            descriptionId: description.requireID(),
            locationId: location.requireID(),
            userId: userId
        )
        try await waypoint.create(on: db)
        return waypoint
    }
}

extension WaypointWaypointModel {
    func load(on db: Database) async throws {
        try await self.loadTitle(on: db)
        try await self.loadDescription(on: db)
        try await self.loadLocation(on: db)
    }
    
    func loadTitle(on db: Database) async throws {
        try await self.$title.load(on: db)
        try await self.title.load(on: db)
    }
    
    func loadDescription(on db: Database) async throws {
        try await self.$description.load(on: db)
        try await self.description.load(on: db)
    }
    
    func loadLocation(on db: Database) async throws {
        try await self.$location.load(on: db)
        try await self.location.load(on: db)
    }
}
