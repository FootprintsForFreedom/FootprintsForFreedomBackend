//
//  Request+AccessControl.swift
//  
//
//  Created by niklhut on 14.05.22.
//

import Vapor
import AppApi

extension Request {
    func onlyForVerifiedUser() async throws {
        /// Require user to be signed in
        let authenticatedUser = try self.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: self.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a admin or higher
        guard user.verified else {
            throw Abort(.forbidden)
        }
    }
    
    func onlyFor(_ role: User.Role) async throws {
        /// Require user to be signed in
        let authenticatedUser = try self.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: self.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a admin or higher
        guard user.role >= role else {
            throw Abort(.forbidden)
        }
    }
    
    func onlyFor(_ user: UserAccountModel, or role: User.Role) async throws {
        /// Require user to be signed in
        let authenticatedUser = try self.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let requestedUser = try await UserAccountModel.find(authenticatedUser.id, on: self.db) else {
            throw Abort(.unauthorized)
        }
        /// require the model id to be the user id or the user to be an moderator
        guard user.id == requestedUser.id || requestedUser.role >= role else {
            throw Abort(.forbidden)
        }
    }
}
