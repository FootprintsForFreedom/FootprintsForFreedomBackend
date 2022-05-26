//
//  MediaDetailModel.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Vapor
import Fluent

final class MediaDetailModel: DetailModel {
    typealias Module = MediaModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var title: FieldKey { "title" }
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
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    @Field(key: FieldKeys.v1.source) var source: String
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: MediaRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: MediaFileModel
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?

    init() { }
    
    init(
        verified: Bool,
        title: String,
        detailText: String,
        source: String,
        languageId: UUID,
        repositoryId: UUID,
        fileId: UUID,
        userId: UUID
    ) {
        self.verified = verified
        self.title = title
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
    var _$verified: FieldProperty<MediaDetailModel, Bool> { $verified }
    var _$updatedAt: TimestampProperty<MediaDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$repository: ParentProperty<MediaDetailModel, MediaRepositoryModel> { $repository }
}

// TODO: maybe hash the file contents to verify the file was not edited in the filesystem --> data integrity
// mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
