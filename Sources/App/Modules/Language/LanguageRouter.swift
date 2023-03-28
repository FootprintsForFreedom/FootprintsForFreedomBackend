//
//  LanguageRouter.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor

struct LanguageRouter: RouteCollection {
    let apiController = LanguageApiController()
    
    func boot(routes: RoutesBuilder) throws {
        
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
        apiController.setupPriorityRoutes(routes)
    }
}
