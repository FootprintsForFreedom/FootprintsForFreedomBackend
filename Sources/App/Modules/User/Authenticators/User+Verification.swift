//
//  User+Verification.swift
//  
//
//  Created by niklhut on 06.07.22.
//

import Vapor

extension UserAccountModel {
    /// Creates a new verification token for the user.
    ///
    /// If an old verification token still exists it will be deleted and therefore invalid.
    ///
    /// - Parameter req: The request on which to verify the token.
    func createNewVerificationToken(_ req: Request) async throws {
        /// load the verification token and delete it if present
        try await $verificationToken.load(on: req.db)
        if let oldVerificationToken = verificationToken {
            try await oldVerificationToken.delete(on: req.db)
        }
        /// create new verification token
        let verificationToken = try generateVerificationToken()
        try await verificationToken.create(on: req.db)
    }
    
    /// Verifies a user token.
    /// - Parameters:
    ///   - req: The request on which to verify the token.
    ///   - inputToken: The input token to be verified.
    /// - Throws: The function throws an error if the given token is invalid.
    func verifyToken(_ req: Request, _ inputToken: String) async throws {
        try await $verificationToken.load(on: req.db)
        /// confirm a token is saved for the user
        guard let verificationToken = verificationToken else {
            throw Abort(.unauthorized)
        }
        /// confirm the token is not older than 24 hours
        guard let createdAt = verificationToken.createdAt, abs(createdAt.timeIntervalSinceNow) < 60 * 60 * 60 * 24 else {
            throw Abort(.unauthorized)
        }
        /// verify the token in the request equals the token saved for that user
        guard inputToken == verificationToken.value else {
            throw Abort(.unauthorized)
        }
    }
}

