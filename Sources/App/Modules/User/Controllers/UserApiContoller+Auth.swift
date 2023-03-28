//
//  UserApiController+Auth.swift
//  
//
//  Created by niklhut on 04.02.22.
//

import Vapor
import AppApi

extension User.Token.Detail: Content {}

extension UserApiController {
    func signInApi(req: Request) async throws -> User.Token.Detail {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
        /// create a token for the user
        let token = try user.generateToken()
        try await token.create(on: req.db)
        /// return the own detail representation of the user
        let userDetail = User.Account.Detail.ownDetail(id: user.id!, name: user.name, email: user.email, school: user.school, verified: user.verified, role: user.role)
        return User.Token.Detail(id: token.id!, access_token: token.value, user: userDetail)
    }
    
    // TODO: problem when singing out in web app would be logged out as well
    
    func signOutApi(req: Request) async throws -> HTTPStatus {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// Query user tokens on database and get all tokens for that user
        let tokens = try await UserTokenModel.query(on: req.db)
            .filter(\.$user.$id, .equal, authenticatedUser.id)
            .all()
        /// delete all tokens belonging to the current user
        try await tokens.delete(on: req.db)
        /// log the user out
        req.auth.logout(AuthenticatedUser.self)
        /// return ok if user was signed out successfully
        return .ok
    }
    
    func setupAuthRoutes(_ routes: RoutesBuilder) {
        routes
            .grouped(UserCredentialsAuthenticator())
            .grouped(UserBasicAuthenticator())
            .post("sign-in", use: signInApi)
        
        routes
            .grouped(AuthenticatedUser.guardMiddleware())
            .post("sign-out", use: signOutApi)

    }
}
