//
//  WaypointRepositoryModel.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import Vapor
import Fluent

final class WaypointRepositoryModel: RepositoryModel, Tagable, Reportable {
    typealias Module = WaypointModule
    
    static var identifier: String { "repositories" }
    
    struct FieldKeys {
        struct v1 {
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Children(for: \.$repository) var details: [WaypointDetailModel]
    @Children(for: \.$repository) var locations: [WaypointLocationModel]
    @Children(for: \.$waypoint) var media: [MediaRepositoryModel]
    @Children(for: \.$repository) var reports: [WaypointReportModel]
    
    @Siblings(through: WaypointTagModel.self, from: \.$waypoint, to: \.$tag) var tags: [TagRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension WaypointRepositoryModel {
    var _$details: ChildrenProperty<WaypointRepositoryModel, WaypointDetailModel> { $details }
    var _$reports: ChildrenProperty<WaypointRepositoryModel, WaypointReportModel> { $reports }
    var _$tags: SiblingsProperty<WaypointRepositoryModel, TagRepositoryModel, WaypointTagModel> { $tags }
    var _$updatedAt: TimestampProperty<WaypointRepositoryModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<WaypointRepositoryModel, DefaultTimestampFormat> { $deletedAt }
}

extension WaypointRepositoryModel {
    func location(
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> WaypointLocationModel? {
        let verifiedLocation = try await $locations
            .query(on: db)
            .filter(\.$status ~~ [.verified, .deleteRequested])
            .sort(\.$updatedAt, sortDirection)
            .first()
        
        if let verifiedLocation = verifiedLocation {
            return verifiedLocation
        } else if needsToBeVerified == false {
            return try await $locations
                .query(on: db)
                .sort(\.$updatedAt, sortDirection)
                .first()
        } else {
            return nil
        }
    }
    
    func deleteDependencies(on db: Database) async throws {
        try await $details.query(on: db).delete()
        try await $locations.query(on: db).delete()
        try await $media.query(on: db).all().concurrentForEach { try await $0.deleteDependencies(on: db) }
        try await $media.query(on: db).delete()
    }
}
