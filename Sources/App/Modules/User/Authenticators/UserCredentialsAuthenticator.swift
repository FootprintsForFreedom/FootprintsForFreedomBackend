//
//  UserCredentialsAuthenticator.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

struct UserCredentialsAuthenticator: AsyncCredentialsAuthenticator {
    struct Credentials: Content {
        let email: String
        let password: String
    }
    
    func authenticate(credentials: Credentials, for req: Request) async throws {
        guard
            let user = try await UserAccountModel
                .query(on: req.db)
                .filter(\.$email == credentials.email)
                .first()
        else {
            return
        }
        
        guard try req.application.password.verify(credentials.password, created: user.password) else {
            return
        }
        req.auth.login(AuthenticatedUser(id: user.id!, email: user.email))
    }
}
