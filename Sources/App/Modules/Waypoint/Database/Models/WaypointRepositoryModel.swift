//
//  WaypointRepositoryModel.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import Vapor
import Fluent

final class WaypointRepositoryModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    static var identifier: String { "repositories" }
    
    @ID() var id: UUID?
    @Children(for: \.$repository) var waypoints: [WaypointWaypointModel]
    
    init() { }
}
