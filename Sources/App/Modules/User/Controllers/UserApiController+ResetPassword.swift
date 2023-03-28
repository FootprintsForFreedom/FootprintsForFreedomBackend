//
//  UserApiController+ResetPassword.swift
//  
//
//  Created by niklhut on 03.02.22.
//

import Vapor
import AppApi

extension UserApiController {
    
    // MARK: - request reset password
    
    @AsyncValidatorBuilder
    func requestResetPasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.email("email")
    }
    
    func requestResetPasswordApi(_ req: Request) async throws -> HTTPStatus {
        try await RequestValidator(requestResetPasswordValidators()).validate(req)
        let input = try req.content.decode(User.Account.ResetPasswordRequest.self)
        
        let possibleUser = try await UserAccountModel.query(on: req.db)
            .filter(\.$email, .equal, input.email)
            .first()
        
        guard let user = possibleUser else {
            throw Abort(.notFound)
        }
        
        try await user.createNewVerificationToken(req)
        
        try await user.$verificationToken.load(on: req.db)
        try await UserRequestPasswordResetMail.send(for: user, on: req)
        
        return .ok
    }
    
    // MARK: - reset password
    
    @AsyncValidatorBuilder
    func resetPasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("token")
        KeyedContentValidator<String>.required("newPassword")
    }
    
    func resetPasswordApi(_ req: Request) async throws -> User.Account.Detail {
        try await RequestValidator(resetPasswordValidators()).validate(req)
        let input = try req.content.decode(User.Account.ResetPassword.self)
        
        let user = try await findBy(identifier(req), on: req.db)
        
        try await user.verifyToken(req, input.token)
        
        /// change the password if the user is verified and the token therefore correct
        try user.setPassword(to: input.newPassword, on: req)
        /// User is verified after password reset since he has access to his email
        user.verified = true
        try await user.update(on: req.db)
        
        return try await detailOutput(req, user)
    }
    
    // MARK: - Routes
    
    func setupResetPasswordRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let resetPasswordRoutes = baseRoutes
            .grouped(ApiModel.pathIdComponent)
            .grouped("resetPassword")
        let requestResetPasswordRoutes = baseRoutes.grouped("resetPassword")
        resetPasswordRoutes.post(use: resetPasswordApi)
        requestResetPasswordRoutes.post(use: requestResetPasswordApi)
    }
}
