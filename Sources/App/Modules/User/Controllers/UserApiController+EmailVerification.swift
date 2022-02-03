//
//  UserApiController+EmailVerification.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension UserApiController: ApiVerificationController {
    typealias VerificationObject = User.Account.Verification
    
    func createVerification(_ req: Request, _ model: UserAccountModel) async throws {
        try await model.$verificationToken.load(on: req.db)
        if let oldVerificationToken = model.verificationToken {
            try await oldVerificationToken.delete(on: req.db)
        }
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789="
        let tokenValue = String((0..<64).map { _ in letters.randomElement()! })
        let verificationToken = UserVerificationTokenModel(value: tokenValue, userId: model.id!)
        try await verificationToken.create(on: req.db)
    }
    
    func requestVerificationResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        /// do not allow a verified user to request a verification token
        guard !model.verified else {
            throw Abort(.forbidden)
        }
        try await model.$verificationToken.load(on: req.db)
        let userVerifyAccountMail = try UserVerifyAccountTemplate(user: model)
        try await userVerifyAccountMail.send(on: req)
        return try await detailOutput(req, model).encodeResponse(for: req)
    }
        
    func verificationInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Verification) async throws {
        guard !model.verified else {
            throw Abort(.forbidden)
        }
        try await model.$verificationToken.load(on: req.db)
        /// confirm a token is saved for the user
        guard let verificationToken = model.verificationToken else {
            throw Abort(.unauthorized)
        }
        /// confirm the token is not older than 24 hours
        guard let createdAt = verificationToken.createdAt, abs(createdAt.timeIntervalSinceNow) < 60 * 60 * 24 else {
            throw Abort(.unauthorized)
        }
        /// verify the token in the request equals the token saved for that user
        guard input.token == verificationToken.value else {
            throw Abort(.unauthorized)
        }
        
        model.verified = true
        try await model.update(on: req.db)
    }
    
    func afterVerification(_ req: Request, _ model: UserAccountModel) async throws {
        /// delete the verification token after it has been used
        try await model.verificationToken?.delete(on: req.db)
    }
    
    func afterCreate(_ req: Request, _ model: UserAccountModel) async throws {
        try await createVerification(req, model)
        try await model.$verificationToken.load(on: req.db)
        let userCreateAccountMail = try UserCreateAccountTemplate(user: model)
        try await userCreateAccountMail.send(on: req)
    }
    
    func verificationResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
}
