//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

//struct UserSessionAuthenticator: AsyncSessionAuthenticator {
//    typealias User = AuthenticatedUser
//    
//    func authenticate(sessionID: User.SessionID, for req: Request) async throws {
//        guard let user = try await UserAccountModel.find(sessionID, on: req.db) else {
//            return
//        }
//        req.auth.login(AuthenticatedUser(id: user.id!, email: user.email))
//    }
//}
