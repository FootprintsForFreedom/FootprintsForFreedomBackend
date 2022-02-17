//
//  UserApiController+GetOwnUser.swift
//  
//
//  Created by niklhut on 04.02.22.
//

import Vapor

extension UserApiController: ApiDetailOwnUserController {
    typealias DetailObject = User.Account.Detail
    
    func detailOwnUserInput(_ req: Request) async throws -> UserAccountModel {
        guard let authenticatedUser = req.auth.get(AuthenticatedUser.self) else {
            throw Abort(.unauthorized)
        }
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
        return user
    }
    
    func detailOwnUserOutput(_ req: Request, _ model: UserAccountModel) async throws -> User.Account.Detail {
        try await detailOutput(req, model)
    }
}
