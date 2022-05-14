//
//  File.swift
//  
//
//  Created by niklhut on 14.05.22.
//

import Vapor

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
}
