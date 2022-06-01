//
//  WaypointRepositoryModel.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import Vapor
import Fluent

final class WaypointRepositoryModel: RepositoryModel {
    typealias Module = WaypointModule
    typealias Detail = WaypointDetailModel
    
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
    
    @Siblings(through: WaypointTagModel.self, from: \.$waypoint, to: \.$tag) var tags: [TagRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension WaypointRepositoryModel {
    var _$details: ChildrenProperty<WaypointRepositoryModel, WaypointDetailModel> { $details }
}

extension WaypointRepositoryModel {
    func location(
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> WaypointLocationModel? {
        let verifiedLocation = try await $locations
            .query(on: db)
            .filter(\.$verified == true)
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
}

extension WaypointRepositoryModel {
    func tagList(_ req: Request) async throws -> [Tag.Detail.List] {
        let verifiedTags = try await $tags.query(on: req.db)
            .filter(WaypointTagModel.self, \.$verified == true)
            .all()
        
        return try await verifiedTags.concurrentMap { tagRepository in
            guard let detail = try await tagRepository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
                return nil
            }
            return try .init(id: tagRepository.requireID(), title: detail.title)
        }
        .compactMap { $0 }
    }
}
