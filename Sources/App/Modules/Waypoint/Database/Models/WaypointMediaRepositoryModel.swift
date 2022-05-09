//
//  WaypointMediaRepositoryModel.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

final class WaypointMediaRepositoryModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    static var identifier: String { "media_repositories" }
    
    struct FieldKeys {
        struct v1 {
            static var waypointId: FieldKey { "waypoint_id" }
        }
    }
    
    @ID() var id: UUID?
    @Children(for: \.$mediaRepository) var media: [WaypointMediaDescriptionModel]
    
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointWaypointModel
    
    init() { }
}
