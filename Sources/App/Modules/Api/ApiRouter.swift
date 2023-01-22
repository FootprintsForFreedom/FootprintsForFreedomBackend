//
//  ApiRouter.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

struct ApiRouter: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {}
    
    func setUpRoutesHooks(app: Application) throws {
        let apiRoutes = app.routes
            .grouped("api")
            .grouped("v1")
        
        let _: [Void] = app.invokeAll("api-routes-v1", args: ["routes": apiRoutes])
        let _: [Void] = app.invokeAll("api-redirects", args: ["routes": app.routes])
    }
}
