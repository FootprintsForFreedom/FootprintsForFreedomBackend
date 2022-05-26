//
//  WaypointDetailModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class WaypointDetailModel: DetailModel {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var title: FieldKey { "title" }
            static var detailText: FieldKey { "detailText" }
            static var languageId: FieldKey { "language_id" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    
    // TODO: likes as sibling?
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        verified: Bool = false,
        title: String,
        detailText: String,
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.verified = verified
        self.title = title
        self.detailText = detailText
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension WaypointDetailModel {
    var _$verified: FieldProperty<WaypointDetailModel, Bool> { $verified }
    var _$language: ParentProperty<WaypointDetailModel, LanguageModel> { $language }
    var _$updatedAt: TimestampProperty<WaypointDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$repository: ParentProperty<WaypointDetailModel, WaypointRepositoryModel> { $repository }
}

extension WaypointDetailModel: Equatable {
    static func == (lhs: WaypointDetailModel, rhs: WaypointDetailModel) -> Bool {
        lhs.id == rhs.id
    }
}
