//
//  StaticContentModule.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor

struct StaticContentModule: ModuleInterface {
    let router = StaticContentRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(StaticContentMigrations.v1())
        app.migrations.add(StaticContentMigrations.seed())
        app.hooks.register("api-routes-v1", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}
