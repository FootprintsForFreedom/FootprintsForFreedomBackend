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
            static var titleId: FieldKey { "title_id" }
            static var descriptionId: FieldKey { "description_id" }
            static var sourceId: FieldKey { "source_id" }
            static var group: FieldKey { "group" }
            static var waypointId: FieldKey { "waypoint_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    
    @Parent(key: FieldKeys.v1.titleId) var title: EditableObjectModel<String>
    @Parent(key: FieldKeys.v1.descriptionId) var description: EditableObjectModel<String>
    @Parent(key: FieldKeys.v1.sourceId) var source: EditableObjectModel<String>
    
    @Enum(key: FieldKeys.v1.group) var group: Waypoint.Media.Group
    
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointWaypointModel
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    
    init() { }
}
