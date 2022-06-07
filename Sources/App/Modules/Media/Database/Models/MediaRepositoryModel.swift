//
//  MediaRepositoryModel.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

final class MediaRepositoryModel: RepositoryModel {
    typealias Module = MediaModule
    typealias Detail = MediaDetailModel
    
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
    
    @Children(for: \.$repository) var details: [MediaDetailModel]
    
    @Siblings(through: MediaTagModel.self, from: \.$media, to: \.$tag) var tags: [TagRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension MediaRepositoryModel {
    var _$details: ChildrenProperty<MediaRepositoryModel, MediaDetailModel> { $details }
}

extension MediaRepositoryModel {
    func deleteDependencies(on database: Database) async throws {
        try await $details
            .query(on: database)
            .field(\.$media.$id)
            .unique()
            .all()
            .concurrentForEach { try await MediaFileModel.find($0.$media.id, on: database)?.delete(on: database) }
        
        try await $details.query(on: database).delete()
        // TODO: service that deletes soft delted entries after a certain time (-> .evn?) -> also delete the media fieles!
    }
}

extension MediaRepositoryModel {
    func tagList(_ req: Request) async throws -> [Tag.Detail.List] {
        let verifiedTags = try await $tags.query(on: req.db)
            .filter(MediaTagModel.self, \.$status ~~ [.verified, .deleteRequested])
            .all()
        
        return try await verifiedTags.concurrentCompactMap { tagRepository in
            guard let detail = try await tagRepository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
                return nil
            }
            return try .init(id: tagRepository.requireID(), title: detail.title, slug: detail.slug)
        }
    }
}
