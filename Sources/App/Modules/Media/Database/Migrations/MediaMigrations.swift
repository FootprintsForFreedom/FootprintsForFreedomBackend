//
//  MediaMigrations.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

enum MediaMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let mediaGroup = try await db.enum(Waypoint.Media.Group.pathKey)
                .case(Waypoint.Media.Group.video.rawValue)
                .case(Waypoint.Media.Group.audio.rawValue)
                .case(Waypoint.Media.Group.document.rawValue)
                .create()
            
            try await db.schema(MediaRepositoryModel.schema)
                .id()
            
                .field(MediaRepositoryModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(MediaRepositoryModel.FieldKeys.v1.waypointId, references: WaypointWaypointModel.schema, .id, onDelete: .cascade)
            
                .create()
            
            try await db.schema(MediaFileModel.schema)
                .id()
                .field(MediaFileModel.FieldKeys.v1.mediaDirectory, .string, .required)
                .unique(on: MediaFileModel.FieldKeys.v1.mediaDirectory)
            
                .field(MediaFileModel.FieldKeys.v1.group, mediaGroup, .required)
            
                .field(MediaFileModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(MediaFileModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(MediaFileModel.FieldKeys.v1.createdAt, .datetime, .required)
            
                .create()
            
            try await db.schema(MediaDescriptionModel.schema)
                .id()
                .field(MediaDescriptionModel.FieldKeys.v1.verified, .bool, .required)
                .field(MediaDescriptionModel.FieldKeys.v1.title, .string, .required)
                .field(MediaDescriptionModel.FieldKeys.v1.description, .string, .required)
                .field(MediaDescriptionModel.FieldKeys.v1.source, .string, .required)
            
                .field(MediaDescriptionModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(MediaDescriptionModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(MediaDescriptionModel.FieldKeys.v1.mediaRepositoryId, .uuid, .required)
                .foreignKey(MediaDescriptionModel.FieldKeys.v1.mediaRepositoryId, references: MediaRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(MediaDescriptionModel.FieldKeys.v1.mediaId, .uuid, .required)
                .foreignKey(MediaDescriptionModel.FieldKeys.v1.mediaId, references: MediaFileModel.schema, .id, onDelete: .cascade)
            
                .field(MediaDescriptionModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(MediaDescriptionModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(MediaDescriptionModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointLocationModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointLocationModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(MediaDescriptionModel.schema).delete()
            try await db.schema(MediaFileModel.schema).delete()
            try await db.schema(MediaRepositoryModel.schema).delete()
            try await db.enum(Waypoint.Media.Group.pathKey).delete()
        }
    }
}
