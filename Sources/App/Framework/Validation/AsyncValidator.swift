//
//  AsyncValidator.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Asynchronously validates a request
public protocol AsyncValidator {
    /// The key at which to find the value to validate.
    var key: String { get }
    /// The error message sent when the validation fails.
    var message: String { get }
    
    /// Validates a request.
    /// - Parameters:
    ///   - req: The request to validate.
    ///   - validationObject: The part of the request to validate.
    /// - Returns: An error if the validation fails.
    func validate(_ req: Request, _ validationObject: RequestValidationObject) async throws -> ValidationErrorDetail?
}

public extension AsyncValidator {
    /// The error to when the validation fails.
    var error: ValidationErrorDetail {
        .init(key: key, message: message)
    }
}

/// Contains possible objects of the request to validate.
///
/// The validation objects include the content and the query of the request.
public enum RequestValidationObject {
    case content
    case query
}
