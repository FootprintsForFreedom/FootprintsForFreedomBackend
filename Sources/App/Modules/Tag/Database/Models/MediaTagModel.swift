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
            static var tagId: FieldKey { "tag_id" }
            static var mediaId: FieldKey { "media_id" }
        }
    }
    
    @ID() var id: UUID?
    @Parent(key: FieldKeys.v1.tagId) var tag: TagRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: MediaRepositoryModel
    
    init() { }
    
    init(media: MediaRepositoryModel, tag: TagRepositoryModel) throws {
        self.$media.id = try media.requireID()
        self.$tag.id = try tag.requireID()
    }
}
