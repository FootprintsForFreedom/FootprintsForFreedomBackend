//
//  TagRepositoryModel.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent

final class TagRepositoryModel: DatabaseModelInterface {
    typealias Module = TagModule
    
    static var schema = "tags"
    
    struct FieldKeys {
        struct v1 {
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Children(for: \.$repository) var details: [TagDetailModel]
    
    @Siblings(through: WaypointTagModel.self, from: \.$tag, to: \.$waypoint) var waypoints: [WaypointRepositoryModel]
    @Siblings(through: MediaTagModel.self, from: \.$tag, to: \.$media) var media: [MediaRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension TagRepositoryModel {
    func detail(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> TagDetailModel? {
        var query = self.$details
            .query(on: db)
            .join(LanguageModel.self, on: \TagDetailModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$languageCode == languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        if needsToBeVerified {
            query = query.filter(\.$verified == true)
        }
        query = query.sort(\.$updatedAt, sortDirection)
        
        return try await query.first()
    }
    
    func detail(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> TagDetailModel? {
        for languageCode in languageCodesByPriority {
            if let detail = try await detail(for: languageCode, needsToBeVerified: needsToBeVerified, on: db, sort: sortDirection) {
                return detail
            }
        }
        return nil
    }
}
