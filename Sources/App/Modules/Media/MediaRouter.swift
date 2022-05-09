//
//  MediaRouter.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor

struct MediaRouter: RouteCollection {
    
    let apiController = MediaApiController()
    
    func boot(routes: RoutesBuilder) throws {
        
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
    }
}
