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
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(WaypointReportModel.schema).delete()
            try await db.schema(WaypointDetailModel.schema).delete()
            try await db.schema(WaypointLocationModel.schema).delete()
            try await db.schema(WaypointRepositoryModel.schema).delete()
        }
    }
}
