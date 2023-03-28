//
//  TagModule.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor

struct TagModule: ModuleInterface {
    let router = TagRouter()
    
    func boot(_ app: Application) throws {
        try app.migrations.add(TagMigrations.v1(elastic: app.elastic))
        app.hooks.register("api-routes-v1", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}
