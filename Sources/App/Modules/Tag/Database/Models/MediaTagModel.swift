//
//  MediaTagModel.swift
//  
//
//  Created by niklhut on 23.05.22.
//

import Vapor
import Fluent

final class MediaTagModel: DatabaseModelInterface, TagPivot {
    typealias Module = MediaModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var tagId: FieldKey { "tag_id" }
            static var mediaId: FieldKey { "media_id" }
        }
    }
    
    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.status) var status: Status
    
    @Parent(key: FieldKeys.v1.tagId) var tag: TagRepositoryModel
    @Parent(key: FieldKeys.v1.mediaId) var media: MediaRepositoryModel
    
    init() {
        self.status = .pending
    }
    
    init(
        media: MediaRepositoryModel,
        tag: TagRepositoryModel,
        verifiedAt: Date? = nil
    ) throws {
        self.$media.id = try media.requireID()
        self.$tag.id = try tag.requireID()
        self.status = status
    }
}

extension MediaTagModel {
    var _$status: EnumProperty<MediaTagModel, Status> { $status }
}
