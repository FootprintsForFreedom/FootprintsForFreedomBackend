//
//  TagMigrations.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent
import SQLKit
import AppApi

enum TagMigrations {
    struct v1: AsyncMigration {
        let elastic: ElasticHandler
        
        func prepare(on db: Database) async throws {
            try await db.schema(TagRepositoryModel.schema)
                .id()
                .field(TagRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(TagRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(TagRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
            
            let statusType = try await db.enum(Status.pathKey).read()
            
            try await db.schema(TagDetailModel.schema)
                .id()
            
                .field(TagDetailModel.FieldKeys.v1.title, .string , .required)
                .field(TagDetailModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: TagDetailModel.FieldKeys.v1.slug)
                .field(TagDetailModel.FieldKeys.v1.keywords, .array(of: .string), .required)
            
                .field(TagDetailModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(TagDetailModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(TagDetailModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(TagDetailModel.FieldKeys.v1.repositoryId, references: TagRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(TagDetailModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(TagDetailModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)

                .field(TagDetailModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(TagDetailModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(TagDetailModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(TagDetailModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(TagReportModel.schema)
                .id()
            
                .field(TagReportModel.FieldKeys.v1.title, .string , .required)
                .field(TagReportModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: TagReportModel.FieldKeys.v1.slug)
                .field(TagReportModel.FieldKeys.v1.reason, .string, .required)
            
                .field(TagReportModel.FieldKeys.v1.visibleDetailId, .uuid)
                .foreignKey(TagReportModel.FieldKeys.v1.visibleDetailId, references: TagDetailModel.schema, .id, onDelete: .setNull)
            
                .field(TagReportModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(TagReportModel.FieldKeys.v1.repositoryId, references: TagRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(TagReportModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(TagReportModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(TagReportModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(TagReportModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(TagReportModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(TagReportModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(WaypointTagModel.schema)
                .id()
            
                .field(WaypointTagModel.FieldKeys.v1.status, statusType, .required)
            
                .field(WaypointTagModel.FieldKeys.v1.tagId, .uuid, .required)
                .foreignKey(WaypointTagModel.FieldKeys.v1.tagId, references: TagRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(WaypointTagModel.FieldKeys.v1.waypointId, .uuid, .required)
                .foreignKey(WaypointTagModel.FieldKeys.v1.waypointId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
                .create()
            
            try await db.schema(MediaTagModel.schema)
                .id()
            
                .field(MediaTagModel.FieldKeys.v1.status, statusType, .required)
            
                .field(MediaTagModel.FieldKeys.v1.tagId, .uuid, .required)
                .foreignKey(MediaTagModel.FieldKeys.v1.tagId, references: TagRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(MediaTagModel.FieldKeys.v1.mediaId, .uuid, .required)
                .foreignKey(MediaTagModel.FieldKeys.v1.mediaId, references: MediaRepositoryModel.schema, .id, onDelete: .cascade)
            
                .create()
            
            let sqlDatabase = db as! SQLDatabase
            
            try await sqlDatabase.raw("""
            CREATE VIEW \(raw: LatestVerifiedTagModel.schema) AS
            WITH latest_verified_tag_details AS (
                SELECT
                    DISTINCT ON (
                        \(SQLColumn(TagDetailModel.FieldKeys.v1.repositoryId.description, table: TagDetailModel.schema)),
                        \(SQLColumn(TagDetailModel.FieldKeys.v1.languageId.description, table: TagDetailModel.schema))
                    ) *
                FROM
                    \(raw: TagDetailModel.schema)
                WHERE
                    \(SQLColumn(TagDetailModel.FieldKeys.v1.verifiedAt.description, table: TagDetailModel.schema)) IS NOT NULL
                    AND \(SQLColumn(TagDetailModel.FieldKeys.v1.deletedAt.description, table: TagDetailModel.schema)) IS NULL
                ORDER BY
                    \(SQLColumn(TagDetailModel.FieldKeys.v1.repositoryId.description, table: TagDetailModel.schema)),
                    \(SQLColumn(TagDetailModel.FieldKeys.v1.languageId.description, table: TagDetailModel.schema)),
                    \(SQLColumn(TagDetailModel.FieldKeys.v1.verifiedAt.description, table: TagDetailModel.schema)) DESC
            )
            SELECT
                details.\(raw: TagDetailModel.FieldKeys.v1.repositoryId.description) as \(raw: FieldKey.id.description),
                details.\(raw: FieldKey.id.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.detailId.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.title.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.slug.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.keywords.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.userId.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.detailUserId.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.verifiedAt.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.detailVerifiedAt.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.createdAt.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.detailCreatedAt.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.updatedAt.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.detailUpdatedAt.description),
                details.\(raw: TagDetailModel.FieldKeys.v1.deletedAt.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.detailDeletedAt.description),
                languages.\(raw: FieldKey.id.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.languageId.description),
                languages.\(raw: LanguageModel.FieldKeys.v1.languageCode.description),
                languages.\(raw: LanguageModel.FieldKeys.v1.name.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.languageName.description),
                languages.\(raw: LanguageModel.FieldKeys.v1.isRTL.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.languageIsRTL.description),
                languages.\(raw: LanguageModel.FieldKeys.v1.priority.description) as \(raw: LatestVerifiedTagModel.FieldKeys.v1.languagePriority.description)
            FROM
                latest_verified_tag_details details
                INNER JOIN \(raw: LanguageModel.schema) ON \(SQLColumn(FieldKey.id.description, table: LanguageModel.schema)) = details.\(raw: TagDetailModel.FieldKeys.v1.languageId.description)
            WHERE
                \(SQLColumn(LanguageModel.FieldKeys.v1.priority.description, table: LanguageModel.schema)) IS NOT NULL
            """)
            .run()
        }
        
        func revert(on db: Database) async throws {
            let sqlDatabase = db as! SQLDatabase
            try await sqlDatabase.raw("DROP VIEW latest_verified_tag_details").run()
            try await db.schema(TagReportModel.schema).delete()
            try await db.schema(TagDetailModel.schema).delete()
            try await db.schema(WaypointTagModel.schema).delete()
            try await db.schema(MediaTagModel.schema).delete()
            try await db.schema(TagRepositoryModel.schema).delete()
            try await elastic.deleteIndex(LatestVerifiedTagModel.Elasticsearch.self, for: LanguageModel.activeLanguages(on: db))
        }
    }
}
