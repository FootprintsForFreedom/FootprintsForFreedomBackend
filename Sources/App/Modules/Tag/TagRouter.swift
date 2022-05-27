//
//  TagRouter.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor

struct TagRouter: RouteCollection {
    
    let apiController = TagApiController()
    
    func boot(routes: RoutesBuilder) throws {
        
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
        apiController.setupVerificationRoutes(routes)
    }
}
