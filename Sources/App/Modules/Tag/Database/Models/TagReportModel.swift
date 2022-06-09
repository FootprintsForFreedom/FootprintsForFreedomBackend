//
//  TagReportModel.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

final class TagReportModel: ReportModel {
    typealias Module = TagModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var reason: FieldKey { "reason" }
            static var visibleDetailId: FieldKey { "visible_detail_id" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.status) var status: Status
    
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.reason) var reason: String
    
    @OptionalParent(key: FieldKeys.v1.visibleDetailId) var visibleDetail: TagDetailModel?
    @Parent(key: FieldKeys.v1.repositoryId) var repository: TagRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() {
        self.status = .pending
    }
    
    init(
        status: Status,
        title: String,
        slug: String,
        reason: String,
        visibleDetailId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.status = status
        self.title = title
        self.slug = slug
        self.reason = reason
        self.$visibleDetail.id = visibleDetailId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension TagReportModel {
    var _$slug: FieldProperty<TagReportModel, String> { $slug }
    var _$status: EnumProperty<TagReportModel, Status> { $status }
    var _$reason: FieldProperty<TagReportModel, String> { $reason }
    var _$visibleDetail: OptionalParentProperty<TagReportModel, TagDetailModel> { $visibleDetail }
    var _$repository: ParentProperty<TagReportModel, TagRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<TagReportModel, UserAccountModel> { $user }
    var _$updatedAt: TimestampProperty<TagReportModel, DefaultTimestampFormat> { $updatedAt }
}