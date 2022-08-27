//
//  TagRepositoryModel.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent

final class TagRepositoryModel: RepositoryModel, Reportable {
    typealias Module = TagModule
    
    static var identifier = "repositories"
    
    struct FieldKeys {
        struct v1 {
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Children(for: \.$repository) var details: [TagDetailModel]
    @Children(for: \.$repository) var reports: [TagReportModel]
    
    @Siblings(through: WaypointTagModel.self, from: \.$tag, to: \.$waypoint) var waypoints: [WaypointRepositoryModel]
    @Siblings(through: MediaTagModel.self, from: \.$tag, to: \.$media) var media: [MediaRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension TagRepositoryModel {
    static var ownKeyPathOnDetail: KeyPath<TagDetailModel, ParentProperty<TagDetailModel, TagRepositoryModel>> { \.$repository }
    var _$details: ChildrenProperty<TagRepositoryModel, TagDetailModel> { $details }
    var _$reports: ChildrenProperty<TagRepositoryModel, TagReportModel> { $reports }
    var _$updatedAt: TimestampProperty<TagRepositoryModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<TagRepositoryModel, DefaultTimestampFormat> { $deletedAt }
}

extension TagRepositoryModel: Hashable {
    static func == (lhs: TagRepositoryModel, rhs: TagRepositoryModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
