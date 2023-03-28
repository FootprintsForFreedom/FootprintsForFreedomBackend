//
//  RequestValidator.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Validator for a request.
public struct RequestValidator {
    /// All validators that need to be checked.
    public var validators: [AsyncValidator]
    
    /// Initializes the request validator with all required validator fields.
    /// - Parameter validators: The required validators.
    public init(_ validators: [AsyncValidator]) {
        self.validators = validators
    }
    
    /// Validates a request.
    /// - Parameters:
    ///   - req: The request to validate.
    ///   - validationObject: The part of the request to validate.
    ///   - message:The error message  sent when the validation fails.
    public func validate(_ req: Request, _ validationObject: RequestValidationObject = .content, message: String? = nil) async throws {
        var result: [ValidationErrorDetail] = []
        for validator in validators {
            if result.contains(where: { $0.key == validator.key }) {
                continue
            }
            if let res = try await validator.validate(req, validationObject) {
                result.append(res)
            }
        }
        if !result.isEmpty {
            throw ValidationAbort(abort: Abort(.badRequest, reason: message), details: result)
        }
    }
}
