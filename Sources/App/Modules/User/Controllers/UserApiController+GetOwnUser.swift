//
//  UserApiController+GetOwnUser.swift
//  
//
//  Created by niklhut on 04.02.22.
//

import Vapor
import AppApi

extension UserApiController {
    func detailOwnUserApi(_ req: Request) async throws -> User.Account.Detail {
        guard let authenticatedUser = req.auth.get(AuthenticatedUser.self) else {
            throw Abort(.unauthorized)
        }
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await detailOutput(req, user)
    }
    
    func setupDetailOwnUserRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped("me")
        existingModelRoutes.get(use: detailOwnUserApi)
    }
}
