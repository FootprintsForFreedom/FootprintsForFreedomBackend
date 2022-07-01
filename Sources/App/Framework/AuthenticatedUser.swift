//
//  AuthenticatedUser.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Represents an authenticated user.
public struct AuthenticatedUser: Authenticatable {
    /// The user id.
    public let id: UUID
    /// The email of the user.
    public let email: String
    
    /// Initializes an authenticated user.
    /// - Parameters:
    ///   - id: The user id.
    ///   - email: The email of the user.
    public init(id: UUID, email: String) {
        self.id = id
        self.email = email
    }
}
