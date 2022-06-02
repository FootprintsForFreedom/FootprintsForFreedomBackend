//
//  WaypointTagModel.swift
//  
//
//  Created by niklhut on 22.05.22.
//

import Vapor
import Fluent

final class WaypointTagModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var deleteRequested: FieldKey { "delete_requested" }
            static var tagId: FieldKey { "tag_id" }
            static var waypointId: FieldKey { "waypoint_id" }
        }
    }
    
    @ID() var id: UUID?
    @Parent(key: FieldKeys.v1.tagId) var tag: TagRepositoryModel
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointRepositoryModel
    
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Field(key: FieldKeys.v1.deleteRequested) var deleteRequested: Bool
    
    init() {
        self.verified = false
        self.deleteRequested = false
    }
    
    init(waypoint: WaypointRepositoryModel, tag: TagRepositoryModel) throws {
        self.$waypoint.id = try waypoint.requireID()
        self.$tag.id = try tag.requireID()
        self.verified = false
        self.deleteRequested = false
    }
}
