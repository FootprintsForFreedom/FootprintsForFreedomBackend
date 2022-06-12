//
//  StaticContentMigrations.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor
import Fluent

enum StaticContentMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let _ = try await db.enum(StaticContent.Snippet.pathKey)
                .case(StaticContent.Snippet.username.rawValue)
                .case(StaticContent.Snippet.appName.rawValue)
                .case(StaticContent.Snippet.verificationLink.rawValue)
                .create()
            
            try await db.schema(StaticContentRepositoryModel.schema)
                .id()
            
                .field(StaticContentRepositoryModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: StaticContentRepositoryModel.FieldKeys.v1.slug)
            
                .field(StaticContentRepositoryModel.FieldKeys.v1.requiredSnippets, .sql(raw: "text[]"), .required)
            
                .field(StaticContentRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(StaticContentRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(StaticContentRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            let statusType = try await db.enum(Status.pathKey).read()
            
            try await db.schema(StaticContentDetailModel.schema)
                .id()
            
                .field(StaticContentDetailModel.FieldKeys.v1.status, statusType, .required)
                .field(StaticContentDetailModel.FieldKeys.v1.moderationTitle, .string , .required)
                .field(StaticContentDetailModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: StaticContentDetailModel.FieldKeys.v1.slug)
                .field(StaticContentDetailModel.FieldKeys.v1.title, .string , .required)
                .field(StaticContentDetailModel.FieldKeys.v1.text, .string, .required)
            
                .field(StaticContentDetailModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(StaticContentDetailModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(StaticContentDetailModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(StaticContentDetailModel.FieldKeys.v1.repositoryId, references: StaticContentRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(StaticContentDetailModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(StaticContentDetailModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(StaticContentDetailModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(StaticContentDetailModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(StaticContentDetailModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(StaticContentDetailModel.schema).delete()
            try await db.schema(StaticContentRepositoryModel.schema).delete()
            try await db.enum(StaticContent.Snippet.pathKey).delete()
        }
    }
}
