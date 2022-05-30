//
//  TagDetailModel.swift
//  
//
//  Created by niklhut on 22.05.22.
//

import Vapor
import Fluent

final class TagDetailModel: DetailModel {
    
    typealias Module = TagModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var title: FieldKey { "title" }
            static var keywords: FieldKey { "keywords" }
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
    @Field(key: FieldKeys.v1.keywords) var keywords: [String]
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: TagRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        verified: Bool,
        title: String,
        keywords: [String],
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.verified = verified
        self.title = title
        self.keywords = keywords
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension TagDetailModel {
    var _$verified: FieldProperty<TagDetailModel, Bool> { $verified }
    var _$language: ParentProperty<TagDetailModel, LanguageModel> { $language }
    var _$repository: ParentProperty<TagDetailModel, TagRepositoryModel> { $repository }
    var _$updatedAt: TimestampProperty<TagDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$user: OptionalParentProperty<TagDetailModel, UserAccountModel> { $user }
}
