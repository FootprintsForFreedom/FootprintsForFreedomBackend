//
//  MediaRepositoryModel.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

final class MediaRepositoryModel: RepositoryModel, Tagable, Reportable {
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
    
    @Children(for: \.$repository) var details: [MediaDetailModel]
    @Children(for: \.$repository) var reports: [MediaReportModel]
    
    @Siblings(through: MediaTagModel.self, from: \.$media, to: \.$tag) var tags: [TagRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension MediaRepositoryModel {
    static var ownKeyPathOnDetail: KeyPath<MediaDetailModel, ParentProperty<MediaDetailModel, MediaRepositoryModel>> { \.$repository }
    var _$details: ChildrenProperty<MediaRepositoryModel, MediaDetailModel> { $details }
    var _$reports: ChildrenProperty<MediaRepositoryModel, MediaReportModel> { $reports }
    var _$tags: SiblingsProperty<MediaRepositoryModel, TagRepositoryModel, MediaTagModel> { $tags }
    var _$updatedAt: TimestampProperty<MediaRepositoryModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<MediaRepositoryModel, DefaultTimestampFormat> { $deletedAt}
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
        // TODO: service that deletes soft deleted entries after a certain time (-> .evn?) -> also delete the media fieles!
    }
}
