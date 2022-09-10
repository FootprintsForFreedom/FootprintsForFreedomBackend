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
            let mediaGroup = try await db.enum(Media.Detail.Group.pathKey)
                .case(Media.Detail.Group.video.rawValue)
                .case(Media.Detail.Group.audio.rawValue)
                .case(Media.Detail.Group.image.rawValue)
                .case(Media.Detail.Group.document.rawValue)
                .create()
            
            try await db.schema(MediaRepositoryModel.schema)
                .id()
            
                .field(MediaRepositoryModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(MediaRepositoryModel.FieldKeys.v1.waypointId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(MediaRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(MediaRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(MediaRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(MediaFileModel.schema)
                .id()
                .field(MediaFileModel.FieldKeys.v1.mediaDirectory, .string, .required)
                .unique(on: MediaFileModel.FieldKeys.v1.mediaDirectory)
            
                .field(MediaFileModel.FieldKeys.v1.group, mediaGroup, .required)
            
                .field(MediaFileModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(MediaFileModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(MediaFileModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(MediaFileModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(MediaFileModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(MediaDetailModel.schema)
                .id()
                .field(MediaDetailModel.FieldKeys.v1.title, .string, .required)
                .field(MediaDetailModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: MediaDetailModel.FieldKeys.v1.slug)
                .field(MediaDetailModel.FieldKeys.v1.detailText, .string, .required)
                .field(MediaDetailModel.FieldKeys.v1.source, .string, .required)
            
                .field(MediaDetailModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(MediaDetailModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(MediaDetailModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(MediaDetailModel.FieldKeys.v1.repositoryId, references: MediaRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(MediaDetailModel.FieldKeys.v1.mediaId, .uuid, .required)
                .foreignKey(MediaDetailModel.FieldKeys.v1.mediaId, references: MediaFileModel.schema, .id, onDelete: .cascade)
            
                .field(MediaDetailModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(MediaDetailModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(MediaDetailModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(MediaDetailModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(MediaDetailModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(MediaDetailModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(MediaReportModel.schema)
                .id()
            
                .field(MediaReportModel.FieldKeys.v1.title, .string , .required)
                .field(MediaReportModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: MediaReportModel.FieldKeys.v1.slug)
                .field(MediaReportModel.FieldKeys.v1.reason, .string, .required)
            
                .field(MediaReportModel.FieldKeys.v1.visibleDetailId, .uuid)
                .foreignKey(MediaReportModel.FieldKeys.v1.visibleDetailId, references: MediaDetailModel.schema, .id, onDelete: .setNull)
            
                .field(MediaReportModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(MediaReportModel.FieldKeys.v1.repositoryId, references: MediaRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(MediaReportModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(MediaReportModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(MediaReportModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(MediaReportModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(MediaReportModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(MediaReportModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(MediaReportModel.schema).delete()
            try await db.schema(MediaDetailModel.schema).delete()
            try await db.schema(MediaFileModel.schema).delete()
            try await db.schema(MediaRepositoryModel.schema).delete()
            try await db.enum(Media.Detail.Group.pathKey).delete()
        }
    }
}
