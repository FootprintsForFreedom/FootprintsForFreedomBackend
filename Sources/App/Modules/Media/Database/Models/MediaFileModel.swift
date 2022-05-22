//
//  MediaFileModel.swift
//  
//
//  Created by niklhut on 08.05.22.
//

import Vapor
import Fluent

final class MediaFileModel: DatabaseModelInterface {
    typealias Module = MediaModule
    
    struct FieldKeys {
        struct v1 {
            static var mediaDirectory: FieldKey { "media_directory" }
            static var group: FieldKey { "group" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.mediaDirectory) var mediaDirectory: String
    
    @Children(for: \.$media) var detailText: [MediaDetailModel]
    
    @Enum(key: FieldKeys.v1.group) var group: Media.Media.Group
    
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        mediaDirectory: String,
        group: Media.Media.Group,
        userId: UUID
    ) {
        self.mediaDirectory = mediaDirectory
        self.group = group
        self.$user.id = userId
    }
}
