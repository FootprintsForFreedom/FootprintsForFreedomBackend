//
//  WaypointMigrations.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

enum WaypointMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let mediaGroup = try await db.enum(Waypoint.Media.Group.pathKey)
                .case(Waypoint.Media.Group.video.rawValue)
                .case(Waypoint.Media.Group.audio.rawValue)
                .case(Waypoint.Media.Group.document.rawValue)
                .create()
            
            try await db.schema(WaypointWaypointModel.schema)
                .id()
                .field(WaypointWaypointModel.FieldKeys.v1.verified, .bool, .required)
            
                .field(WaypointWaypointModel.FieldKeys.v1.locationId, .uuid, .required)
                .foreignKey(WaypointWaypointModel.FieldKeys.v1.locationId, references: EditableObjectRepositoryModel<Waypoint.Location>.schema, .id, onDelete: .cascade)
                .unique(on: WaypointWaypointModel.FieldKeys.v1.locationId)
            
                .field(WaypointWaypointModel.FieldKeys.v1.titleId, .uuid , .required)
                .foreignKey(WaypointWaypointModel.FieldKeys.v1.titleId, references: EditableObjectRepositoryModel<String>.schema, .id, onDelete: .cascade)
                .unique(on: WaypointWaypointModel.FieldKeys.v1.titleId)
            
                .field(WaypointWaypointModel.FieldKeys.v1.descriptionId, .uuid , .required)
                .foreignKey(WaypointWaypointModel.FieldKeys.v1.descriptionId, references: EditableObjectRepositoryModel<String>.schema, .id, onDelete: .cascade)
                .unique(on: WaypointWaypointModel.FieldKeys.v1.descriptionId)
            
                .create()
            
            try await db.schema(WaypointMediaModel.schema)
                .id()
                .field(WaypointMediaModel.FieldKeys.v1.verified, .bool, .required)
            
                .field(WaypointMediaModel.FieldKeys.v1.titleId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.titleId, references: EditableObjectRepositoryModel<String>.schema, .id, onDelete: .cascade)
                .unique(on: WaypointMediaModel.FieldKeys.v1.titleId)
            
                .field(WaypointMediaModel.FieldKeys.v1.descriptionId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.descriptionId, references: EditableObjectRepositoryModel<String>.schema, .id, onDelete: .cascade)
                .unique(on: WaypointMediaModel.FieldKeys.v1.descriptionId)
            
                .field(WaypointMediaModel.FieldKeys.v1.sourceId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.sourceId, references: EditableObjectRepositoryModel<String>.schema, .id, onDelete: .cascade)
                .unique(on: WaypointMediaModel.FieldKeys.v1.sourceId)
            
                .field(WaypointMediaModel.FieldKeys.v1.group, mediaGroup, .required)
            
                .field(WaypointMediaModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.waypointId, references: WaypointWaypointModel.schema, .id, onDelete: .cascade)
            
                .field(WaypointMediaModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointMediaModel.FieldKeys.v1.createdAt, .datetime, .required)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(WaypointWaypointModel.schema).delete()
        }
    }
}
