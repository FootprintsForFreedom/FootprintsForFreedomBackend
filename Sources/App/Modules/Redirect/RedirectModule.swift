//
//  RedirectModule.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Vapor

struct RedirectModule: ModuleInterface {
    let router = RedirectRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(RedirectMigrations.v1())
        app.hooks.register("api-routes-v1", use: router.apiRoutesHook)
        app.hooks.register("api-redirects", use: router.redirectHook)
        
        try router.boot(routes: app.routes)
    }
}
