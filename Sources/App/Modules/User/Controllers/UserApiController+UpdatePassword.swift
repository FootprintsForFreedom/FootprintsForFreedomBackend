//
//  UserApiController+UpdatePassword.swift
//  
//
//  Created by niklhut on 03.02.22.
//

import Vapor
import AppApi

extension UserApiController {
    
    @AsyncValidatorBuilder
    func updatePasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("currentPassword")
        KeyedContentValidator<String>.required("newPassword")
    }
    
    func updatePasswordApi(_ req: Request) async throws -> User.Account.Detail {
        /// Require user to be logged in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        try await RequestValidator(updatePasswordValidators()).validate(req)
        
        let input = try req.content.decode(User.Account.ChangePassword.self)
        let model = try await findBy(identifier(req), on: req.db)
        
        /// Assure the user itself changes the password
        guard model.id == user.id else {
            throw Abort(.forbidden)
        }
        
        /// Verify current password
        guard try req.application.password.verify(input.currentPassword, created: model.password) else {
            throw Abort(.forbidden)
        }
        
        /// Change the password
        try model.setPassword(to: input.newPassword, on: req)

        try await model.update(on: req.db)
        
        return try await detailOutput(req, model)
    }
    
    func setupUpdatePasswordRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped(ApiModel.pathIdComponent).grouped("updatePassword")
        existingModelRoutes.put(use: updatePasswordApi)
    }
}
