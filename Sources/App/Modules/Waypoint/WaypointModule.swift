//
//  WaypointModule.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor

struct WaypointModule: ModuleInterface {
    
    let router = WaypointRouter()
    
    func boot(_ app: Application) throws {
        try app.migrations.add(WaypointMigrations.v1(elastic: app.elastic))
        
        app.hooks.register("api-routes-v1", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}
