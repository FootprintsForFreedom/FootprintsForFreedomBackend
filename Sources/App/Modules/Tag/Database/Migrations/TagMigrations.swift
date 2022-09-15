//
//  TagMigrations.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent
import SQLKit

enum TagMigrations {
    struct v1: AsyncMigration {
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
            CREATE VIEW latest_verified_tag_details AS
            WITH latest_verified_tag_details AS (
                SELECT
                    DISTINCT ON (repository_id, language_id) *
                FROM
                    tag_details
                WHERE
                    verified_at IS NOT NULL
                    AND deleted_at IS NULL
                ORDER BY
                    repository_id,
                    language_id,
                    verified_at DESC
            )
            SELECT
                details.repository_id AS id,
                details.id AS detail_id,
                details.title,
                details.slug,
                details.keywords,
                details.user_id AS detail_user_id,
                details.verified_at AS detail_verified_at,
                details.created_at AS detail_created_at,
                details.updated_at AS detail_updated_at,
                details.deleted_at AS detail_deleted_at,
                languages.id AS language_id,
                languages.language_code,
                languages.name AS language_name,
                languages.is_rtl AS language_is_rtl,
                languages.priority AS language_priority
            FROM
                latest_verified_tag_details details
                INNER JOIN languages ON languages.id = details.language_id
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
        }
    }
}
