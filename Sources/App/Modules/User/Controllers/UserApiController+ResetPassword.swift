//
//  UserApiController+ResetPassword.swift
//  
//
//  Created by niklhut on 03.02.22.
//

import Vapor

extension UserApiController: ApiResetPasswordController {
    typealias ResetPasswordRequestObject = User.Account.ResetPasswordRequest
    typealias ResetPasswordObject = User.Account.ResetPassword
    
    @AsyncValidatorBuilder
    func requestResetPasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.email("email")
    }
    
    func requestResetPasswordInput(_ req: Request, _ input: User.Account.ResetPasswordRequest) async throws -> UserAccountModel {
        let possibleUser = try await UserAccountModel.query(on: req.db)
            .filter(\.$email, .equal, input.email)
            .first()
        
        guard let user = possibleUser else {
            throw Abort(.notFound)
        }
        return user
    }
    
    func requestResetPasswordResponse(_ req: Request, _ model: UserAccountModel) async throws -> HTTPStatus {
        try await model.$verificationToken.load(on: req.db)
        let userRequestPasswordResetMail = try UserRequestPasswordResetMail(user: model)
        try await userRequestPasswordResetMail.send(on: req)
        return .ok
    }
    
    @AsyncValidatorBuilder
    func resetPasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("token")
        KeyedContentValidator<String>.required("newPassword")
    }
    
    func resetPasswordInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.ResetPassword) async throws {
        /// verify the user
        let userVerificationInput = User.Account.Verification(token: input.token)
        try await verificationInput(req, model, userVerificationInput)
        
        /// change the password if the user is verified and the token therefore correct
        try model.setPassword(to: input.newPassword, on: req)
    }
    
    func resetPasswordResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        return try await User.Account.Detail.ownDetail(
            id: model.id!,
            name: model.name,
            email: model.email,
            school: model.school,
            verified: model.verified,
            role: model.role
        ).encodeResponse(for: req)
    }
}
