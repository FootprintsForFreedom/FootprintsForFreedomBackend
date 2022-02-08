//
//  UserApiController+ChangeRole.swift
//  
//
//  Created by niklhut on 07.02.22.
//

import Vapor

extension UserApiController: ApiChangeRoleController {
    typealias ChangeRoleObject = User.Account.ChangeRole
    
    @AsyncValidatorBuilder
    func changeRoleValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("newRole")
    }
    
    func changeRoleInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.ChangeRole) async throws {
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
        /// Assure the user changing the role is not lower than the user being edited and the new role
        guard model.role <= user.role && input.newRole <= user.role else {
            throw Abort(.forbidden)
        }
        /// Set new role
        model.role = input.newRole
    }
    
    func changeRoleResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
}
