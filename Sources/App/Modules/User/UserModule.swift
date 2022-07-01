//
//  UserModule.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

struct UserModule: ModuleInterface {
    
    let router = UserRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(UserMigrations.v1())
        app.migrations.add(UserMigrations.seed())
        
        app.middleware.use(UserTokenAuthenticator())
        
        app.hooks.register("api-routes-v1", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}

