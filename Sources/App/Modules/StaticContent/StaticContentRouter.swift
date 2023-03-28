//
//  StaticContentRouter.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor

struct StaticContentRouter: RouteCollection {
    
    let apiController = StaticContentApiController()
    
    func boot(routes: RoutesBuilder) throws {
        
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
    }
}
