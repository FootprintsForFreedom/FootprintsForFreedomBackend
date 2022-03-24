//
//  WaypointMediaModel.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Vapor
import Fluent

final class WaypointMediaModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var title: FieldKey { "title" }
            static var description: FieldKey { "description" }
            static var source: FieldKey { "source" }
            static var group: FieldKey { "group" }
            static var waypointId: FieldKey { "waypoint_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.description) var description: String
    @Field(key: FieldKeys.v1.source) var source: String
    
    @Enum(key: FieldKeys.v1.group) var group: Waypoint.Media.Group
    
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointWaypointModel
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    
    init() { }
}

// mabye also store medias in repository --> store media repositories --> one media per language and fallback for others like with waypoints
