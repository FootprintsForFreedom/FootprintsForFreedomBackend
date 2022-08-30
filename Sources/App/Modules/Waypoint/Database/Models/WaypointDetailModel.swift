//
//  WaypointDetailModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class WaypointDetailModel: TitledDetailModel {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detail_text" }
            static var languageId: FieldKey { "language_id" }
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
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    
    // TODO: likes as sibling?
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() {
        self.status = .pending
    }
    
    init(
        id: UUID? = nil,
        status: Status = .pending,
        title: String,
        slug: String,
        detailText: String,
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.status = status
        self.title = title
        self.slug = slug
        self.detailText = detailText
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension WaypointDetailModel {
    var _$status: EnumProperty<WaypointDetailModel, Status> { $status }
    var _$language: ParentProperty<WaypointDetailModel, LanguageModel> { $language }
    var _$updatedAt: TimestampProperty<WaypointDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<WaypointDetailModel, DefaultTimestampFormat> { $deletedAt }
    var _$repository: ParentProperty<WaypointDetailModel, WaypointRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<WaypointDetailModel, UserAccountModel> { $user }
    var _$slug: FieldProperty<WaypointDetailModel, String> { $slug }
}

extension WaypointDetailModel: Equatable {
    static func == (lhs: WaypointDetailModel, rhs: WaypointDetailModel) -> Bool {
        lhs.id == rhs.id
    }
}
