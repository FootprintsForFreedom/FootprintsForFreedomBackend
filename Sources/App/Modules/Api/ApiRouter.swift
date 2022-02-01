//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

struct ApiRouter: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {}

    func setUpRoutesHooks(app: Application) throws {
        let apiRoutes = app.routes
//            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped("api")

        let _: [Void] = app.invokeAll("api-routes", args: ["routes": apiRoutes])
    }
    
    
}
