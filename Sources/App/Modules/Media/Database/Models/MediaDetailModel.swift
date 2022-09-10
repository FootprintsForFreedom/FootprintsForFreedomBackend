//
//  MediaDetailModel.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Vapor
import Fluent

final class MediaDetailModel: TitledDetailModel {
    typealias Module = MediaModule
    
    struct FieldKeys {
        struct v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detail_text" }
            static var source: FieldKey { "source" }
            static var repositoryId: FieldKey { "repository_id" }
            static var mediaId: FieldKey { "media_id" }
            static var languageId: FieldKey { "language_id" }
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
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    @Field(key: FieldKeys.v1.source) var source: String
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: MediaRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: MediaFileModel
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
        detailText: String,
        source: String,
        languageId: UUID,
        repositoryId: UUID,
        fileId: UUID,
        userId: UUID
    ) {
        self.verifiedAt = verifiedAt
        self.title = title
        self.slug = slug
        self.detailText = detailText
        self.source = source
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$media.id = fileId
        self.$user.id = userId
    }
}

extension MediaDetailModel {
    var _$language: ParentProperty<MediaDetailModel, LanguageModel> { $language }
    var _$verifiedAt: OptionalFieldProperty<MediaDetailModel, Date> { $verifiedAt }
    var _$updatedAt: TimestampProperty<MediaDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<MediaDetailModel, DefaultTimestampFormat> { $deletedAt }
    var _$repository: ParentProperty<MediaDetailModel, MediaRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<MediaDetailModel, UserAccountModel> { $user }
    var _$slug: FieldProperty<MediaDetailModel, String> { $slug }
}

// TODO: maybe hash the file contents to verify the file was not edited in the filesystem --> data integrity
// mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
