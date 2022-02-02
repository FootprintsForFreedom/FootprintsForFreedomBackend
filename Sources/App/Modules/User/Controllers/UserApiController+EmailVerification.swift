//
//  UserApiController+EmailVerification.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension UserApiController: ApiVerificationController {
    typealias VerificationObject = User.Account.Verification
    
//    @AsyncValidatorBuilder
//    func verificationValidators() -> [AsyncValidator] {
//        KeyedContentValidator<String>.required("token")
//    }
    
    func verificationInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Verification) async throws {
        guard !model.verified else {
            throw Abort(.forbidden)
        }
        try await model.$verificationToken.load(on: req.db)
        guard input.token == model.verificationToken?.value else {
            throw Abort(.unauthorized)
        }
        
        model.verified = true
        try await model.update(on: req.db)
        // TODO: expire token after 24 hours
    }
    
    func afterVerification(_ req: Request, _ model: UserAccountModel) async throws {
        /// delete the verification token after it has been used
        try await model.verificationToken?.delete(on: req.db)
    }
    
    func afterCreate(_ req: Request, _ model: UserAccountModel) async throws {        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789="
        let tokenValue = String((0..<64).map { _ in letters.randomElement()! })
        let verificationToken = UserVerificationTokenModel(value: tokenValue, userId: model.id!)
        try await verificationToken.create(on: req.db)
        
        try await model.$verificationToken.load(on: req.db)
        let userCreateAccountMail = try UserCreateAccountTemplate(user: model)
        try await userCreateAccountMail.send(on: req)
    }
    
    func verificationResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
}
