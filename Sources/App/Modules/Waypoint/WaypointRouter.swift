//
//  WaypointRouter.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor

struct WaypointRouter: RouteCollection {
    
    let apiController = WaypointApiController()
    
    func boot(routes: RoutesBuilder) throws {
        
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
        apiController.setupSearchRoutes(routes)
        apiController.setupVerificationRoutes(routes)
        apiController.setupReportRoutes(routes)
    }
}
