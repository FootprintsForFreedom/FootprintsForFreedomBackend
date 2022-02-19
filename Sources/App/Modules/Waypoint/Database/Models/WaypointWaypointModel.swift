//
//  WaypointWaypointModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class WaypointWaypointModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var locationId: FieldKey { "location_id" }
            static var titleId: FieldKey { "title_id" }
            static var descriptionId: FieldKey { "description_id" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    
    @Parent(key: FieldKeys.v1.locationId) var location: EditableObjectRepositoryModel<Waypoint.Location>
    @Parent(key: FieldKeys.v1.titleId) var title: EditableObjectRepositoryModel<String>
    @Parent(key: FieldKeys.v1.descriptionId) var description: EditableObjectRepositoryModel<String>
    
    @Children(for: \.$waypoint) var media: [WaypointMediaModel]
    
    // TODO: likes as sibling?
    
    init() { }
    
    init(verified: Bool) {
        self.verified = verified
    }
    
    init(
        id: UUID? = nil,
        titleId: UUID,
        descriptionId: UUID,
        locationId: UUID,
        verified: Bool
    ) {
        self.id = id
        self.$title.id = titleId
        self.$description.id = descriptionId
        self.$location.id = locationId
        self.verified = verified
    }
}

extension WaypointWaypointModel {
    func load(on db: Database) async throws {
        try await self.$location.load(on: db)
        try await self.location.load(on: db)
        try await self.$title.load(on: db)
        try await self.title.load(on: db)
        try await self.$description.load(on: db)
        try await self.description.load(on: db)
    }
}
