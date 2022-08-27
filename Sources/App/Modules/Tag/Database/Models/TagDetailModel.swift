//
//  TagDetailModel.swift
//  
//
//  Created by niklhut on 22.05.22.
//

import Vapor
import Fluent

final class TagDetailModel: TitledDetailModel {
    typealias Module = TagModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
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
    @Enum(key: FieldKeys.v1.status) var status: Status
    
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.keywords) var keywords: [String]
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
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
        keywords: [String],
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.status = status
        self.title = title
        self.slug = slug
        self.keywords = keywords
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension TagDetailModel {
    var ownKeyPathForRepository: KeyPath<TagRepositoryModel, ChildrenProperty<TagRepositoryModel, TagDetailModel>> { \._$details }
    var _$status: EnumProperty<TagDetailModel, Status> { $status }
    var _$language: ParentProperty<TagDetailModel, LanguageModel> { $language }
    var _$repository: ParentProperty<TagDetailModel, TagRepositoryModel> { $repository }
    var _$updatedAt: TimestampProperty<TagDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<TagDetailModel, DefaultTimestampFormat> { $deletedAt }
    var _$user: OptionalParentProperty<TagDetailModel, UserAccountModel> { $user }
    var _$slug: FieldProperty<TagDetailModel, String> { $slug }
}
