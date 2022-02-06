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
    
    /// Require user to be logged in
    func updatePasswordInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.ChangePassword) async throws {
        guard let user = req.auth.get(AuthenticatedUser.self) else {
            throw Abort(.unauthorized)
        }
        
        /// Assure the user itself changes the password
        guard model.id == user.id else {
            throw Abort(.forbidden)
        }
        
        /// Verify current password
        guard try req.application.password.verify(input.currentPassword, created: model.password) else {
            throw Abort(.forbidden)
        }
        
        /// Confirm new password meets conditions
        guard input.newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil &&
                input.newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil &&
                input.newPassword.rangeOfCharacter(from: .decimalDigits) != nil &&
                input.newPassword.rangeOfCharacter(from: .newlines) == nil
        else {
            throw Abort(.badRequest)
        }
        
        /// Update the password
        model.password = try req.application.password.hash(input.newPassword)
    }
    
    func updatePasswordResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func setupUpdatePasswordRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        let baseRoutes = getBaseRoutes(protectedRoutes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent).grouped("updatePassword")
        existingModelRoutes.put(use: updatePasswordApi)
    }
}
