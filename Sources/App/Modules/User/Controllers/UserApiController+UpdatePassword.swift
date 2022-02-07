//
//  UserApiController+UpdatePassword.swift
//  
//
//  Created by niklhut on 03.02.22.
//

import Vapor

extension UserApiController: ApiUpdatePasswordController {
    typealias UpdatePasswordObject = User.Account.ChangePassword
    
    @AsyncValidatorBuilder
    func updatePasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("currentPassword")
        KeyedContentValidator<String>.required("newPassword")
    }
    
    func beforeUpdatePassword(_ req: Request, _ model: UserAccountModel) async throws {
        /// Require user to be logged in
        let user = try req.auth.require(AuthenticatedUser.self)
        /// Assure the user itself changes the password
        guard model.id == user.id else {
            throw Abort(.forbidden)
        }
    }
    
    func updatePasswordInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.ChangePassword) async throws {
        /// Verify current password
        guard try req.application.password.verify(input.currentPassword, created: model.password) else {
            throw Abort(.forbidden)
        }
        
        /// Change the password
        try model.setPassword(to: input.newPassword, on: req)
    }
    
    func updatePasswordResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
}
