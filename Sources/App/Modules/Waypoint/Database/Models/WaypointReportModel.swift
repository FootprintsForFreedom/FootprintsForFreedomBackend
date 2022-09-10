//
//  WaypointReportModel.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

final class WaypointReportModel: ReportModel {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var reason: FieldKey { "reason" }
            static var visibleDetailId: FieldKey { "visible_detail_id" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var verifiedAt: FieldKey { "verified_at" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.reason) var reason: String
    
    @OptionalParent(key: FieldKeys.v1.visibleDetailId) var visibleDetail: WaypointDetailModel?
    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @OptionalField(key: FieldKeys.v1.verifiedAt) var verifiedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        verifiedAt: Date?,
        title: String,
        slug: String,
        reason: String,
        visibleDetailId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.verifiedAt = verifiedAt
        self.title = title
        self.slug = slug
        self.reason = reason
        self.$visibleDetail.id = visibleDetailId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension WaypointReportModel {
    var _$slug: FieldProperty<WaypointReportModel, String> { $slug }
    var _$reason: FieldProperty<WaypointReportModel, String> { $reason }
    var _$visibleDetail: OptionalParentProperty<WaypointReportModel, WaypointDetailModel> { $visibleDetail }
    var _$repository: ParentProperty<WaypointReportModel, WaypointRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<WaypointReportModel, UserAccountModel> { $user }
    var _$verifiedAt: OptionalFieldProperty<WaypointReportModel, Date> { $verifiedAt }
    var _$updatedAt: TimestampProperty<WaypointReportModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<WaypointReportModel, DefaultTimestampFormat> { $deletedAt }
}
