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
        let elastic: ElasticHandler
        
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
            CREATE VIEW \(raw: WaypointSummaryModel.schema) AS
            WITH latest_verified_waypoint_details AS (
                SELECT
                    DISTINCT ON (
                        \(SQLColumn(WaypointDetailModel.FieldKeys.v1.repositoryId.description, table: WaypointDetailModel.schema)),
                        \(SQLColumn(WaypointDetailModel.FieldKeys.v1.languageId.description, table: WaypointDetailModel.schema))
                    ) *
                FROM
                    \(raw: WaypointDetailModel.schema)
                WHERE
                    \(SQLColumn(WaypointDetailModel.FieldKeys.v1.verifiedAt.description, table: WaypointDetailModel.schema)) IS NOT NULL
                    AND \(SQLColumn(WaypointDetailModel.FieldKeys.v1.deletedAt.description, table: WaypointDetailModel.schema)) IS NULL
                ORDER BY
                    \(SQLColumn(WaypointDetailModel.FieldKeys.v1.repositoryId.description, table: WaypointDetailModel.schema)),
                    \(SQLColumn(WaypointDetailModel.FieldKeys.v1.languageId.description, table: WaypointDetailModel.schema)),
                    \(SQLColumn(WaypointDetailModel.FieldKeys.v1.verifiedAt.description, table: WaypointDetailModel.schema)) DESC
            ),
            latest_verified_waypoint_locations AS (
                SELECT
                    DISTINCT ON (
                        \(SQLColumn(WaypointLocationModel.FieldKeys.v1.repositoryId.description, table: WaypointLocationModel.schema))
                    ) *
                FROM
                    \(raw: WaypointLocationModel.schema)
                WHERE
                    \(SQLColumn(WaypointLocationModel.FieldKeys.v1.verifiedAt.description, table: WaypointLocationModel.schema)) IS NOT NULL
                    AND \(SQLColumn(WaypointLocationModel.FieldKeys.v1.deletedAt.description, table: WaypointLocationModel.schema)) IS NULL
                ORDER BY
                    \(SQLColumn(WaypointLocationModel.FieldKeys.v1.repositoryId.description, table: WaypointLocationModel.schema)),
                    \(SQLColumn(WaypointLocationModel.FieldKeys.v1.verifiedAt.description, table: WaypointLocationModel.schema)) DESC
            )
            SELECT
                details.\(raw: WaypointDetailModel.FieldKeys.v1.repositoryId.description) as \(raw: FieldKey.id.description),
                details.\(raw: FieldKey.id.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.detailId.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.title.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.slug.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.detailText.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.userId.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.detailUserId.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.verifiedAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.detailVerifiedAt.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.createdAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.detailCreatedAt.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.updatedAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.detailUpdatedAt.description),
                details.\(raw: WaypointDetailModel.FieldKeys.v1.deletedAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.detailDeletedAt.description),
                locations.\(raw: FieldKey.id.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.locationId.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.latitude.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.longitude.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.userId.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.locationUserId.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.verifiedAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.locationVerifiedAt.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.createdAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.locationCreatedAt.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.updatedAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.locationUpdatedAt.description),
                locations.\(raw: WaypointLocationModel.FieldKeys.v1.deletedAt.description) as \(raw: WaypointSummaryModel.FieldKeys.v1.locationDeletedAt.description),
                \(SQLColumn(FieldKey.id.description, table: LanguageModel.schema)) as \(raw: WaypointSummaryModel.FieldKeys.v1.languageId.description),
                \(SQLColumn(LanguageModel.FieldKeys.v1.languageCode.description, table: LanguageModel.schema)),
                \(SQLColumn(LanguageModel.FieldKeys.v1.name.description, table: LanguageModel.schema)) as \(raw: WaypointSummaryModel.FieldKeys.v1.languageName.description),
                \(SQLColumn(LanguageModel.FieldKeys.v1.isRTL.description, table: LanguageModel.schema)) as \(raw: WaypointSummaryModel.FieldKeys.v1.languageIsRTL.description),
                \(SQLColumn(LanguageModel.FieldKeys.v1.priority.description, table: LanguageModel.schema)) as \(raw: WaypointSummaryModel.FieldKeys.v1.languagePriority.description)
            FROM
                latest_verified_waypoint_details details
                INNER JOIN latest_verified_waypoint_locations locations ON locations.\(raw: WaypointLocationModel.FieldKeys.v1.repositoryId.description) = details.\(raw: WaypointDetailModel.FieldKeys.v1.repositoryId.description)
                INNER JOIN \(raw: LanguageModel.schema) ON \(SQLColumn(FieldKey.id.description, table: LanguageModel.schema)) = details.\(raw: WaypointDetailModel.FieldKeys.v1.languageId.description)
            WHERE
                \(SQLColumn(LanguageModel.FieldKeys.v1.priority.description, table: LanguageModel.schema)) IS NOT NULL
            """)
            .run()
        }
        
        func revert(on db: Database) async throws {
            let sqlDatabase = db as! SQLDatabase
            try await sqlDatabase.raw("DROP VIEW \(raw: WaypointSummaryModel.schema)").run()
            try await db.schema(WaypointReportModel.schema).delete()
            try await db.schema(WaypointDetailModel.schema).delete()
            try await db.schema(WaypointLocationModel.schema).delete()
            try await db.schema(WaypointRepositoryModel.schema).delete()
            try await elastic.deleteIndex(WaypointSummaryModel.Elasticsearch.self, for: LanguageModel.activeLanguages(on: db))
        }
    }
}
