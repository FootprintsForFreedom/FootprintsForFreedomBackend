//
//  MediaRepositoryModel.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

final class MediaRepositoryModel: DatabaseModelInterface {
    typealias Module = MediaModule
    
    static var identifier: String { "repositories" }
    
    struct FieldKeys {
        struct v1 {
            static var waypointId: FieldKey { "waypoint_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointRepositoryModel
    
    @Children(for: \.$mediaRepository) var media: [MediaDetailModel]
    
    @Siblings(through: MediaTagModel.self, from: \.$media, to: \.$tag) var tags: [TagRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension MediaRepositoryModel {
    func media(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> MediaDetailModel? {
        var query = self.$media
            .query(on: db)
            .join(LanguageModel.self, on: \MediaDetailModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$languageCode == languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        if needsToBeVerified {
            query = query.filter(\.$verified == true)
        }
        query = query.sort(\.$updatedAt, sortDirection)
        
        return try await query.first()
    }
    
    func media(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> MediaDetailModel? {
        for languageCode in languageCodesByPriority {
            if let waypoint = try await media(for: languageCode, needsToBeVerified: needsToBeVerified, on: db, sort: sortDirection){
                return waypoint
            }
        }
        return nil
    }
}

extension MediaRepositoryModel {
    func deleteDependencies(on database: Database) async throws {
        try await $media
            .query(on: database)
            .field(\.$media.$id)
            .unique()
            .all()
            .concurrentForEach { try await MediaFileModel.find($0.$media.id, on: database)?.delete(on: database) }
        
        try await $media.query(on: database).delete()
        // TODO: service that deletes soft delted entries after a certain time (-> .evn?) -> also delete the media fieles!
    }
}
