//
//  ValidationError.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Protocol representing validation errors.
struct ValidationError: Codable {
    /// The error message  sent with the failed validation.
    let message: String?
    /// The  additional``ValidationErrorDetail``s.
    let details: [ValidationErrorDetail]
        
    /// Initializes a validation error with message and details.
    /// - Parameters:
    ///   - message:The error message  sent with the failed validation.
    ///   - details: The  additional``ValidationErrorDetail``s.
    init(message: String?, details: [ValidationErrorDetail]) {
        self.message = message
        self.details = details
    }
}

extension ValidationError: Content {}
