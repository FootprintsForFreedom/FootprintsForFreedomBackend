//
//  ValidationErrorDetail.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// A validation error detail representing an issue with a certain key in the validations.
public struct ValidationErrorDetail: Codable {
    /// The key at which to find the value whose validation failed.
    public var key: String
    /// The error message  sent with the failed validation.
    public var message: String
    
    /// Initialize the validation error detail with a key and message
    /// - Parameters:
    ///   - key: The key at which to find the value whose validation failed.
    ///   - message: The error message  sent with the failed validation.
    public init(key: String, message: String) {
        self.key = key
        self.message = message
    }
}

extension ValidationErrorDetail: Content {}
