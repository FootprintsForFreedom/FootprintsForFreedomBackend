//
//  MediaMigrations.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent
import SQLKit
import AppApi

enum MediaMigrations {
    struct v1: AsyncMigration {
        let elastic: ElasticHandler
        
        func prepare(on db: Database) async throws {
            let mediaFileType = try await db.enum(Media.Detail.FileType.pathKey)
                .case(Media.Detail.FileType.video.rawValue)
                .case(Media.Detail.FileType.audio.rawValue)
                .case(Media.Detail.FileType.image.rawValue)
                .case(Media.Detail.FileType.document.rawValue)
                .create()
                
            try await db.schema(MediaRepositoryModel.schema)
                .id()
            
                .field(MediaRepositoryModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(MediaRepositoryModel.FieldKeys.v1.waypointId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(MediaRepositoryModel.FieldKeys.v1.requiredFileType, mediaFileType, .required)
            
                .field(MediaRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(MediaRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(MediaRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(MediaFileModel.schema)
                .id()
                .field(MediaFileModel.FieldKeys.v1.mediaDirectory, .string, .required)
                .unique(on: MediaFileModel.FieldKeys.v1.mediaDirectory)
            
                .field(MediaFileModel.FieldKeys.v1.fileType, mediaFileType, .required)
            
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
            
            let sqlDatabase = db as! SQLDatabase
            
            try await sqlDatabase.raw("""
            CREATE VIEW \(raw: MediaSummaryModel.schema) AS
            WITH latest_verified_media_details AS (
                SELECT
                    DISTINCT ON (
                        \(SQLColumn(MediaDetailModel.FieldKeys.v1.repositoryId.description, table: MediaDetailModel.schema)),
                        \(SQLColumn(MediaDetailModel.FieldKeys.v1.languageId.description, table: MediaDetailModel.schema))
                    ) *
                FROM
                    \(raw: MediaDetailModel.schema)
                WHERE
                    \(SQLColumn(MediaDetailModel.FieldKeys.v1.verifiedAt.description, table: MediaDetailModel.schema)) IS NOT NULL
                    AND \(SQLColumn(MediaDetailModel.FieldKeys.v1.deletedAt.description, table: MediaDetailModel.schema)) IS NULL
                ORDER BY
                    \(SQLColumn(MediaDetailModel.FieldKeys.v1.repositoryId.description, table: MediaDetailModel.schema)),
                    \(SQLColumn(MediaDetailModel.FieldKeys.v1.languageId.description, table: MediaDetailModel.schema)),
                    \(SQLColumn(MediaDetailModel.FieldKeys.v1.verifiedAt.description, table: MediaDetailModel.schema)) DESC
            )
            SELECT
                details.\(raw: MediaDetailModel.FieldKeys.v1.repositoryId.description) as \(raw: FieldKey.id.description),
                details.\(raw: FieldKey.id.description) as \(raw: MediaSummaryModel.FieldKeys.v1.detailId.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.title.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.slug.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.detailText.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.source.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.userId.description) as \(raw: MediaSummaryModel.FieldKeys.v1.detailUserId.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.verifiedAt.description) as \(raw: MediaSummaryModel.FieldKeys.v1.detailVerifiedAt.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.createdAt.description) as \(raw: MediaSummaryModel.FieldKeys.v1.detailCreatedAt.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.updatedAt.description) as \(raw: MediaSummaryModel.FieldKeys.v1.detailUpdatedAt.description),
                details.\(raw: MediaDetailModel.FieldKeys.v1.deletedAt.description) as \(raw: MediaSummaryModel.FieldKeys.v1.detailDeletedAt.description),
                \(SQLColumn(MediaRepositoryModel.FieldKeys.v1.waypointId.description, table: MediaRepositoryModel.schema)),
                \(SQLColumn(FieldKey.id.description, table: MediaFileModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.fileId.description),
                \(SQLColumn(MediaFileModel.FieldKeys.v1.fileType.description, table: MediaFileModel.schema)),
                \(SQLColumn(MediaFileModel.FieldKeys.v1.mediaDirectory.description, table: MediaFileModel.schema)),
                \(SQLColumn(MediaFileModel.FieldKeys.v1.userId.description, table: MediaFileModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.fileUserId.description),
                \(SQLColumn(MediaFileModel.FieldKeys.v1.createdAt.description, table: MediaFileModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.fileCreatedAt.description),
                \(SQLColumn(MediaFileModel.FieldKeys.v1.updatedAt.description, table: MediaFileModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.fileUpdatedAt.description),
                \(SQLColumn(MediaFileModel.FieldKeys.v1.deletedAt.description, table: MediaFileModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.fileDeletedAt.description),
                \(SQLColumn(FieldKey.id.description, table: LanguageModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.languageId.description),
                \(SQLColumn(LanguageModel.FieldKeys.v1.languageCode.description, table: LanguageModel.schema)),
                \(SQLColumn(LanguageModel.FieldKeys.v1.name.description, table: LanguageModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.languageName.description),
                \(SQLColumn(LanguageModel.FieldKeys.v1.isRTL.description, table: LanguageModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.languageIsRTL.description),
                \(SQLColumn(LanguageModel.FieldKeys.v1.priority.description, table: LanguageModel.schema)) as \(raw: MediaSummaryModel.FieldKeys.v1.languagePriority.description)
            FROM
                latest_verified_media_details details
                INNER JOIN \(raw: MediaRepositoryModel.schema) ON \(SQLColumn(FieldKey.id.description, table: MediaRepositoryModel.schema)) = details.\(raw: MediaDetailModel.FieldKeys.v1.repositoryId.description)
                INNER JOIN \(raw: MediaFileModel.schema) ON \(SQLColumn(FieldKey.id.description, table: MediaFileModel.schema)) = details.\(raw: MediaDetailModel.FieldKeys.v1.mediaId.description)
                INNER JOIN \(raw: LanguageModel.schema) ON \(SQLColumn(FieldKey.id.description, table: LanguageModel.schema)) = details.\(raw: MediaDetailModel.FieldKeys.v1.languageId.description)
            WHERE
                \(SQLColumn(LanguageModel.FieldKeys.v1.priority.description, table: LanguageModel.schema)) IS NOT NULL
            """)
            .run()
        }
        
        func revert(on db: Database) async throws {
            let sqlDatabase = db as! SQLDatabase
            try await sqlDatabase.raw("DROP VIEW \(raw: MediaSummaryModel.schema)").run()
            try await db.schema(MediaReportModel.schema).delete()
            try await db.schema(MediaDetailModel.schema).delete()
            try await db.schema(MediaFileModel.schema).delete()
            try await db.schema(MediaRepositoryModel.schema).delete()
            try await db.enum(Media.Detail.FileType.pathKey).delete()
            try await elastic.deleteIndex(MediaSummaryModel.Elasticsearch.self, for: LanguageModel.activeLanguages(on: db))
        }
    }
}
