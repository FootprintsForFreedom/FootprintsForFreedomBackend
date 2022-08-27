//
//  StaticContentDetailModel.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor
import Fluent

final class StaticContentDetailModel: TitledDetailModel {
    typealias Module = StaticContentModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var moderationTitle: FieldKey { "moderation_title" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var text: FieldKey { "text" }
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
    
    @Field(key: FieldKeys.v1.moderationTitle) var moderationTitle: String
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.text) var text: String
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: StaticContentRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() {
        self.status = .verified
    }
    
    init(
        id: UUID? = nil,
        moderationTitle: String,
        slug: String? = nil,
        title: String,
        text: String,
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.status = .verified
        self.id = id
        self.moderationTitle = moderationTitle
        self.slug = slug ?? moderationTitle.slugify()
        self.title = title
        self.text = text
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension StaticContentDetailModel {
    var ownKeyPathOnRepository: KeyPath<StaticContentRepositoryModel, ChildrenProperty<StaticContentRepositoryModel, StaticContentDetailModel>> { \._$details }
    var _$slug: FluentKit.FieldProperty<StaticContentDetailModel, String> { $slug }
    var _$status: FluentKit.EnumProperty<StaticContentDetailModel, AppApi.Status> { $status }
    var _$language: FluentKit.ParentProperty<StaticContentDetailModel, LanguageModel> { $language }
    var _$repository: FluentKit.ParentProperty<StaticContentDetailModel, StaticContentRepositoryModel> { $repository }
    var _$user: FluentKit.OptionalParentProperty<StaticContentDetailModel, UserAccountModel> { $user }
    var _$updatedAt: FluentKit.TimestampProperty<StaticContentDetailModel, FluentKit.DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<StaticContentDetailModel, DefaultTimestampFormat> { $deletedAt }
}

extension StaticContentDetailModel {
    func generateSlug(with accuracy: Date.Accuracy = .none, on db: Database) async throws -> String {
        try await generateSlug(for: self.moderationTitle, self.createdAt, with: accuracy, on: db)
    }
}
