//
//  WaypointMediaModel.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Vapor
import Fluent

final class WaypointMediaDescriptionModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var title: FieldKey { "title" }
            static var description: FieldKey { "description" }
            static var source: FieldKey { "source" }
            static var mediaRepositoryId: FieldKey { "media_repository_id" }
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
    // TODO: rename description (not only here but also in waypoint) to detailText or something similar to avoid coercion form CusotmStringConvertible
    @Field(key: FieldKeys.v1.description) var description: String
    @Field(key: FieldKeys.v1.source) var source: String
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.mediaRepositoryId) var mediaRepository: WaypointMediaRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: WaypointMediaModel
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?

    init() { }
}

// TODO: maybe hash the file contents to verify the file was not edited in the filesystem --> data integrity
// mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
