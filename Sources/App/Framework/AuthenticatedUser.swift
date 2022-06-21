//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public struct AuthenticatedUser: Authenticatable {
    public let id: UUID
    public let email: String
    
    public init(id: UUID, email: String) {
        self.id = id
        self.email = email
    }
}
