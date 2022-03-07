//
//  LanguageModule.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor

struct LanguageModule: ModuleInterface {
    
    let router = LanguageRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(LanguageMigrations.v1())
        app.migrations.add(LanguageMigrations.seed())
        
        app.middleware.use(UserTokenAuthenticator())
        
        app.hooks.register("api-routes", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}
