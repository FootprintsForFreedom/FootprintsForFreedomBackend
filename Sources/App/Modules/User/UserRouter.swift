//
//  UserRouter.swift
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
        
        routes.grouped("api")
            .grouped(AuthenticatedUser.guardMiddleware())
            .post("sign-out", use: apiController.signOutApi)
    }
    
    func apiRoutesHook(_ args: HookArguments) -> Void {
        let routes = args["routes"] as! RoutesBuilder
        
        apiController.setupRoutes(routes)
        apiController.setupDetailOwnUserRoutes(routes)
        apiController.setupUpdatePasswordRoutes(routes)
        apiController.setupVerificationRoutes(routes)
        apiController.setupResetPasswordRoutes(routes)
        apiController.setupChangeRoleRoutes(routes)
    }
    
}
