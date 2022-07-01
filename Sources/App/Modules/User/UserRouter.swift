//
//  UserRouter.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

struct UserRouter: RouteCollection {
    let apiController = UserApiController()
    
    func boot(routes: RoutesBuilder) throws { }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        routes
            .grouped(UserCredentialsAuthenticator())
            .post("sign-in", use: apiController.signInApi)
        
        routes
            .grouped(AuthenticatedUser.guardMiddleware())
            .post("sign-out", use: apiController.signOutApi)
        
        apiController.setupRoutes(routes)
        apiController.setupDetailOwnUserRoutes(routes)
        apiController.setupUpdatePasswordRoutes(routes)
        apiController.setupVerificationRoutes(routes)
        apiController.setupResetPasswordRoutes(routes)
        apiController.setupChangeRoleRoutes(routes)
    }
    
}
