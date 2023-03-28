//
//  RedirectRouter.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Vapor

struct RedirectRouter: RouteCollection {
    let apiController = RedirectApiController()
    let redirectController = RedirectController()
    
    func boot(routes: RoutesBuilder) throws { }
    
    func apiRoutesHook(_ args: HookArguments) {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
    }
    
    func redirectHook(_ args: HookArguments) {
        let routes = args["routes"] as! RoutesBuilder
        
        redirectController.setupRoutes(routes)
    }
}
