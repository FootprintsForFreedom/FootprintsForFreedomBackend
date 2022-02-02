//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

struct UserRouter: RouteCollection {
    
//    let frontendController = UserFrontendController()
    let apiController = UserApiController()
    
    func boot(routes: RoutesBuilder) throws {
//        routes.get("sign-in", use: frontendController.signInView)
//        routes
//            .grouped(UserCredentialsAuthenticator())
//            .post("sign-in", use: frontendController.signInAction)
//
//        routes.get("sign-out", use: frontendController.signOut)
        
        routes.grouped("api")
            .grouped(UserCredentialsAuthenticator())
            .post("sign-in", use: apiController.signInApi)
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
        apiController.setupUpdatePasswordRoutes(routes)
        apiController.setupVerificationRoutes(routes)
    }
    
}
