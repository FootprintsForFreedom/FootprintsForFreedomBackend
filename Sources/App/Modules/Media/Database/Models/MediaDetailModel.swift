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
            static var status: FieldKey { "status" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detailText" }
            static var source: FieldKey { "source" }
            static var repositoryId: FieldKey { "repository_id" }
            static var mediaId: FieldKey { "media_id" }
            static var languageId: FieldKey { "language_id" }
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
    @Field(key: FieldKeys.v1.source) var source: String
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: MediaRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: MediaFileModel
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
        detailText: String,
        source: String,
        languageId: UUID,
        repositoryId: UUID,
        fileId: UUID,
        userId: UUID
    ) {
        self.status = status
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
    var ownKeyPathOnRepository: KeyPath<MediaRepositoryModel, ChildrenProperty<MediaRepositoryModel, MediaDetailModel>> { \._$details }
    var _$status: EnumProperty<MediaDetailModel, Status> { $status }
    var _$language: ParentProperty<MediaDetailModel, LanguageModel> { $language }
    var _$updatedAt: TimestampProperty<MediaDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<MediaDetailModel, DefaultTimestampFormat> { $deletedAt }
    var _$repository: ParentProperty<MediaDetailModel, MediaRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<MediaDetailModel, UserAccountModel> { $user }
    var _$slug: FieldProperty<MediaDetailModel, String> { $slug }
}

// TODO: maybe hash the file contents to verify the file was not edited in the filesystem --> data integrity
// mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
