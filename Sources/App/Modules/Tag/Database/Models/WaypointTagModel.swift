//
//  WaypointTagModel.swift
//  
//
//  Created by niklhut on 22.05.22.
//

import Vapor
import Fluent
import AppApi

final class WaypointTagModel: DatabaseModelInterface, TagPivot {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var tagId: FieldKey { "tag_id" }
            static var waypointId: FieldKey { "waypoint_id" }
        }
    }
    
    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.status) var status: Status
    
    @Parent(key: FieldKeys.v1.tagId) var tag: TagRepositoryModel
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointRepositoryModel
    
    init() {
        self.status = .pending
    }
    
    init(
        waypoint: WaypointRepositoryModel,
        tag: TagRepositoryModel,
        verifiedAt: Date? = nil
    ) throws {
        self.$waypoint.id = try waypoint.requireID()
        self.$tag.id = try tag.requireID()
        self.status = status
    }
}

extension WaypointTagModel {
    var _$status: EnumProperty<WaypointTagModel, Status> { $status }
}
