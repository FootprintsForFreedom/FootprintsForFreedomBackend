//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SwiftHtml

struct UserModule: ModuleInterface {

    let router = UserRouter()

    func boot(_ app: Application) throws {
        app.migrations.add(UserMigrations.v1())
        app.migrations.add(UserMigrations.seed())
        
//        app.middleware.use(UserSessionAuthenticator())
        app.middleware.use(UserTokenAuthenticator())
        
        app.hooks.register("api-routes", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}

