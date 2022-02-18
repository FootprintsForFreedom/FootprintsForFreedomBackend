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
        app.migrations.add(WaypointMigrations.v1())
        
        app.middleware.use(UserTokenAuthenticator())
        
        app.hooks.register("api-routes", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}
