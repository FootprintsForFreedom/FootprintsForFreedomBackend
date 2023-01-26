//
//  UserApiController+EmailVerification.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import AppApi

extension UserApiController {
    
    // MARK: - request verification
    
    func requestVerificationApi(_ req: Request) async throws -> HTTPStatus {
        let user = try await findBy(identifier(req), on: req.db)
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        
        /// do not allow a verified user to request a verification token and require the model id to be the user id
        guard !user.verified && user.id == authenticatedUser.id else {
            throw Abort(.forbidden)
        }
        
        try await user.createNewVerificationToken(req)
        
        try await user.$verificationToken.load(on: req.db)
        try await UserVerifyAccountTemplate.send(for: user, on: req)
        return .ok
    }
       
    // MARK: - Verification
    
    @AsyncValidatorBuilder
    func verificationValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("token")
    }

    
    func verificationApi(_ req: Request) async throws -> User.Account.Detail {
        try await RequestValidator(verificationValidators()).validate(req, .query)
        let input = try req.query.decode(User.Account.Verification.self)
        
        let user = try await findBy(identifier(req), on: req.db)
        
        try await user.verifyToken(req, input.token)
        user.verified = true
        try await user.update(on: req.db)
        
        /// delete the verification token after it has been used
        try await user.verificationToken?.delete(on: req.db)
        
        return try await detailOutput(req, user)
    }
    
    // MARK: - Routes
    
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        let verificationRoutes = existingModelRoutes.grouped("verify")
        let requestVerificationRoutes = existingModelRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped("requestVerification")
        verificationRoutes.post(use: verificationApi)
        requestVerificationRoutes.post(use: requestVerificationApi)
    }
}
