//
//  User+GetToken.swift
//  
//
//  Created by niklhut on 04.02.22.
//

import Vapor

extension UserAccountModel {
    private func generateTokenValue() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789="
        let tokenValue = String((0..<64).map { _ in letters.randomElement()! })
        return tokenValue
    }
    
    func generateToken() throws -> UserTokenModel {
        let tokenValue = generateTokenValue()
        return UserTokenModel(value: tokenValue, userId: self.id!)
    }
    
    func generateVerificationToken() throws -> UserVerificationTokenModel {
        let tokenValue = generateTokenValue()
        return UserVerificationTokenModel(value: tokenValue, userId: self.id!)
    }
}
