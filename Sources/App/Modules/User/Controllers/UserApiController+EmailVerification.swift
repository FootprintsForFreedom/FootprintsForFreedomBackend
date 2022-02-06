//
//  UserApiController+EmailVerification.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension UserApiController: ApiEmailVerificationController {
    typealias VerificationObject = User.Account.Verification
    
    func beforeCreateVerification(_ req: Request, _ model: UserAccountModel) async throws {
        /// do not allow a verified user to request a verification token
        guard !model.verified else {
            throw Abort(.forbidden)
        }
        /// load the verification token and delete it if present
        try await model.$verificationToken.load(on: req.db)
        if let oldVerificationToken = model.verificationToken {
            try await oldVerificationToken.delete(on: req.db)
        }
        /// create new verification token
        let verificationToken = try model.generateVerificationToken()
        try await verificationToken.create(on: req.db)
    }
    
    func requestVerificationInput(_ req: Request, _ model: UserAccountModel) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// require the model id to be the user id
        guard model.id == authenticatedUser.id else {
            throw Abort(.forbidden)
        }
    }
    
    func requestVerificationResponse(_ req: Request, _ model: UserAccountModel) async throws -> HTTPStatus {
        try await model.$verificationToken.load(on: req.db)
        let userVerifyAccountMail = try UserVerifyAccountTemplate(user: model)
        try await userVerifyAccountMail.send(on: req)
        return .ok
    }
        
    func verificationInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Verification) async throws {
        // TODO: test that verified user does not work
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
