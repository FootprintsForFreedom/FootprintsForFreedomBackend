//
//  TagMigrations.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent

enum TagMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(TagRepositoryModel.schema)
                .id()
                .field(TagRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(TagRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(TagRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
            
            try await db.schema(TagDetailModel.schema)
                .id()
            
                .field(TagDetailModel.FieldKeys.v1.verified, .bool, .required)
                .field(TagDetailModel.FieldKeys.v1.title, .string , .required)
                .field(TagDetailModel.FieldKeys.v1.keywords, .array(of: .string), .required)
            
                .field(TagDetailModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(TagDetailModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(TagDetailModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(TagDetailModel.FieldKeys.v1.repositoryId, references: TagRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(TagDetailModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(TagDetailModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(TagDetailModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(TagDetailModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(TagDetailModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(WaypointTagModel.schema)
                .id()
            
                .field(WaypointTagModel.FieldKeys.v1.tagId, .uuid, .required)
                .foreignKey(WaypointTagModel.FieldKeys.v1.tagId, references: TagRepositoryModel.schema, .id)
            
                .field(WaypointTagModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(WaypointTagModel.FieldKeys.v1.waypointId, references: WaypointRepositoryModel.schema, .id)
            
                .field(WaypointTagModel.FieldKeys.v1.verified, .bool, .required)
                .field(WaypointTagModel.FieldKeys.v1.deleteRequested, .bool, .required)
            
                .create()
            
            try await db.schema(MediaTagModel.schema)
                .id()
            
                .field(MediaTagModel.FieldKeys.v1.tagId, .uuid, .required)
                .foreignKey(MediaTagModel.FieldKeys.v1.tagId, references: TagRepositoryModel.schema, .id)
            
                .field(MediaTagModel.FieldKeys.v1.mediaId, .uuid, .required)
                .foreignKey(MediaTagModel.FieldKeys.v1.mediaId, references: MediaRepositoryModel.schema, .id)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(TagDetailModel.schema).delete()
            try await db.schema(WaypointTagModel.schema).delete()
            try await db.schema(MediaTagModel.schema).delete()
            try await db.schema(TagRepositoryModel.schema).delete()
        }
    }
}
