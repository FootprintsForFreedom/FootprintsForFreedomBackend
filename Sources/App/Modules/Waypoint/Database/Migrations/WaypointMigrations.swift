//
//  WaypointMigrations.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent
import SQLKit

enum WaypointMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(WaypointRepositoryModel.schema)
                .id()
                .field(WaypointRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
            
            try await db.schema(WaypointDetailModel.schema)
                .id()
            
                .field(WaypointDetailModel.FieldKeys.v1.title, .string , .required)
                .field(WaypointDetailModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: WaypointDetailModel.FieldKeys.v1.slug)
                .field(WaypointDetailModel.FieldKeys.v1.detailText, .string , .required)
            
                .field(WaypointDetailModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(WaypointDetailModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(WaypointDetailModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(WaypointDetailModel.FieldKeys.v1.repositoryId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(WaypointDetailModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(WaypointDetailModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointDetailModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(WaypointDetailModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointDetailModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointDetailModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(WaypointLocationModel.schema)
                .id()
                .field(WaypointLocationModel.FieldKeys.v1.latitude, .double, .required)
                .field(WaypointLocationModel.FieldKeys.v1.longitude, .double, .required)
            
                .field(WaypointLocationModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(WaypointLocationModel.FieldKeys.v1.repositoryId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(WaypointLocationModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(WaypointLocationModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointLocationModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(WaypointLocationModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointLocationModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointLocationModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(WaypointReportModel.schema)
                .id()
            
                .field(WaypointReportModel.FieldKeys.v1.title, .string , .required)
                .field(WaypointReportModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: WaypointReportModel.FieldKeys.v1.slug)
                .field(WaypointReportModel.FieldKeys.v1.reason, .string, .required)
            
                .field(WaypointReportModel.FieldKeys.v1.visibleDetailId, .uuid)
                .foreignKey(WaypointReportModel.FieldKeys.v1.visibleDetailId, references: WaypointDetailModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointReportModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(WaypointReportModel.FieldKeys.v1.repositoryId, references: WaypointRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(WaypointReportModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(WaypointReportModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(WaypointReportModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(WaypointReportModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(WaypointReportModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(WaypointReportModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            let sqlDatabase = db as! SQLDatabase
            
            try await sqlDatabase.raw("""
            CREATE VIEW waypoint_summaries AS
            WITH latest_verified_waypoint_details AS (
                SELECT
                    DISTINCT ON (repository_id, language_id) *
                FROM
                    waypoint_details
                WHERE
                    verified_at IS NOT NULL
                    AND deleted_at IS NULL
                ORDER BY
                    repository_id,
                    language_id,
                    verified_at DESC
            ),
            latest_verified_waypoint_locations AS (
                SELECT
                    DISTINCT ON (repository_id) *
                FROM
                    waypoint_locations
                WHERE
                    verified_at IS NOT NULL
                    AND deleted_at IS NULL
                ORDER BY
                    repository_id,
                    verified_at DESC
            )
            SELECT
                details.repository_id as id,
                details.id as detail_id,
                details.title,
                details.slug,
                details.detail_text,
                details.user_id as detail_user_id,
                details.verified_at as detail_verified_at,
                details.created_at as detail_created_at,
                details.updated_at as detail_updated_at,
                details.deleted_at as detail_deleted_at,
                locations.id as location_id,
                locations.latitude,
                locations.longitude,
                locations.user_id as location_user_id,
                locations.verified_at as location_verified_at,
                locations.created_at as location_created_at,
                locations.updated_at as location_updated_at,
                locations.deleted_at as location_deleted_at,
                languages.id as language_id,
                languages.language_code,
                languages.name as language_name,
                languages.is_rtl as language_is_rtl,
                languages.priority as language_priority
            FROM
                latest_verified_waypoint_details details
                INNER JOIN latest_verified_waypoint_locations locations ON locations.repository_id = details.repository_id
                INNER JOIN languages ON languages.id = details.language_id
            WHERE
                languages.priority IS NOT NULL
            """)
            .run()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(WaypointReportModel.schema).delete()
            try await db.schema(WaypointDetailModel.schema).delete()
            try await db.schema(WaypointLocationModel.schema).delete()
            try await db.schema(WaypointRepositoryModel.schema).delete()
        }
    }
}
