//
//  MediaModule.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor

struct MediaModule: ModuleInterface {
    let router = MediaRouter()
    
    func boot(_ app: Application) throws {
        try app.migrations.add(MediaMigrations.v1(elastic: app.elastic))
        
        app.hooks.register("api-routes-v1", use: router.apiRoutesHook)
        
        try router.boot(routes: app.routes)
    }
}
