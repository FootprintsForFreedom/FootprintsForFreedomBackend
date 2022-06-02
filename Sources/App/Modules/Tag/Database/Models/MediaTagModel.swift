//
//  MediaTagModel.swift
//  
//
//  Created by niklhut on 23.05.22.
//

import Vapor
import Fluent

final class MediaTagModel: DatabaseModelInterface {
    typealias Module = MediaModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var deleteRequested: FieldKey { "delete_requested" }
            static var tagId: FieldKey { "tag_id" }
            static var mediaId: FieldKey { "media_id" }
        }
    }
    
    @ID() var id: UUID?
    @Parent(key: FieldKeys.v1.tagId) var tag: TagRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: MediaRepositoryModel
    
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Field(key: FieldKeys.v1.deleteRequested) var deleteRequested: Bool
    
    init() {
        self.verified = false
        self.deleteRequested = false
    }
    
    init(media: MediaRepositoryModel, tag: TagRepositoryModel) throws {
        self.$media.id = try media.requireID()
        self.$tag.id = try tag.requireID()
        self.verified = false
        self.deleteRequested = false
    }
}
