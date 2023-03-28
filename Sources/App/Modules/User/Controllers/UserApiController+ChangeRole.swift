//
//  UserApiController+ChangeRole.swift
//  
//
//  Created by niklhut on 07.02.22.
//

import Vapor
import AppApi

extension UserApiController {
    
    @AsyncValidatorBuilder
    func changeRoleValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("newRole")
    }
    
    func changeRoleApi(_ req: Request) async throws -> User.Account.Detail {
        try await req.onlyFor(.admin)
        
        /// Require a user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await RequestValidator(changeRoleValidators()).validate(req)
        let input = try req.content.decode(User.Account.ChangeRole.self)
        let model = try await findBy(identifier(req), on: req.db)
        
        /// Make sure the user does not update himself
        guard user.id != model.id else {
            throw Abort(.forbidden, reason: "You cannot change your own role.")
        }
        
        /// Assure the user changing the role is not lower than the user being edited and the new role
        guard model.role <= user.role && input.newRole <= user.role else {
            throw Abort(.forbidden)
        }
        
        /// Set new role
        model.role = input.newRole
        
        try await model.update(on: req.db)
        
        return try await detailOutput(req, model)
    }
    
    func setupChangeRoleRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped(ApiModel.pathIdComponent)
            .grouped("changeRole")
        existingModelRoutes.put(use: changeRoleApi)
    }
}
