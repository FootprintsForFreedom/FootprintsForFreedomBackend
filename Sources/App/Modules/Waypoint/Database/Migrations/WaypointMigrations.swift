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
            
            try await db.schema(WaypointRepositoryModel.schema)
                .id()
                .create()
            
            try await db.schema(WaypointWaypointModel.schema)
                .id()
            
                .field(WaypointWaypointModel.FieldKeys.v1.verified, .bool, .required)
                .field(WaypointWaypointModel.FieldKeys.v1.title, .string , .required)
                .field(WaypointWaypointModel.FieldKeys.v1.description, .string , .required)
            
                .field(WaypointWaypointModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(WaypointWaypointModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(WaypointWaypointModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(WaypointWaypointModel.FieldKeys.v1.repositoryId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
            // TODO: required may pose problem when deleting user, test please
                .field(WaypointWaypointModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(WaypointWaypointModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointWaypointModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointWaypointModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointWaypointModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(WaypointLocationModel.schema)
                .id()
                .field(WaypointLocationModel.FieldKeys.v1.verified, .bool, .required)
                .field(WaypointLocationModel.FieldKeys.v1.latitude, .double, .required)
                .field(WaypointLocationModel.FieldKeys.v1.longitude, .double, .required)
            
                .field(WaypointLocationModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(WaypointLocationModel.FieldKeys.v1.repositoryId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
            // TODO: required may pose problem when deleting user, test please
                .field(WaypointLocationModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(WaypointLocationModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointLocationModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointLocationModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointLocationModel.FieldKeys.v1.deletedAt, .datetime)

                .create()
            
            try await db.schema(WaypointMediaModel.schema)
                .id()
                .field(WaypointMediaModel.FieldKeys.v1.verified, .bool, .required)
                .field(WaypointMediaModel.FieldKeys.v1.title, .string, .required)
                .field(WaypointMediaModel.FieldKeys.v1.description, .string, .required)
                .field(WaypointMediaModel.FieldKeys.v1.source, .string, .required)
                
                .field(WaypointMediaModel.FieldKeys.v1.group, mediaGroup, .required)
            
                .field(WaypointMediaModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.waypointId, references: WaypointWaypointModel.schema, .id, onDelete: .cascade)
            
                .field(WaypointMediaModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(WaypointMediaModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointMediaModel.FieldKeys.v1.createdAt, .datetime, .required)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(WaypointMediaModel.schema).delete()
            try await db.schema(WaypointWaypointModel.schema).delete()
            try await db.schema(WaypointLocationModel.schema).delete()
            try await db.schema(WaypointRepositoryModel.schema).delete()
            try await db.enum(Waypoint.Media.Group.pathKey).delete()
        }
    }
}
