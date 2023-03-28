//
//  UserBasicAuthenticator.swift
//  
//
//  Created by niklhut on 05.07.22.
//

import Vapor
import Fluent

struct UserBasicAuthenticator: AsyncBasicAuthenticator {
    func authenticate(basic: BasicAuthorization, for req: Request) async throws {
        guard
            let user = try await UserAccountModel
                .query(on: req.db)
                .filter(\.$email == basic.username)
                .first()
        else {
            return
        }
        
        guard try req.application.password.verify(basic.password, created: user.password) else {
            return
        }
        req.auth.login(AuthenticatedUser(id: user.id!, email: user.email))
    }
}
