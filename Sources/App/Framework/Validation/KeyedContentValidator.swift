//
//  KeyedContentValidator.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Used for validating generic, codable keyed content.
public struct KeyedContentValidator<T: Codable>: AsyncValidator {
    public let key: String
    public let message: String
    /// Wether or not this field is required.
    public let optional: Bool
    /// The validation block with the actual validation logic.
    public let validation: (T, Request) async throws -> Bool
    
    /// Initialize the keyed content validator with all given values.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate.
    ///   - message: The error message  sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    ///   - validation: The validation block with the actual validation logic.
    public init(_ key: String,
                _ message: String,
                optional: Bool = false,
                _ validation: @escaping (T, Request) async throws -> Bool) {
        self.key = key
        self.message = message
        self.optional = optional
        self.validation = validation
    }
    
    public func validate(_ req: Request, _ validationObject: RequestValidationObject) async throws -> ValidationErrorDetail? {
        switch validationObject {
        case .content:
            let optionalValue = try? req.content.get(T.self, at: key)
            if let value = optionalValue {
                return try await validation(value, req) ? nil : error
            }
        case .query:
            let optionalValue = try? req.query.get(T.self, at: key)
            if let value = optionalValue {
                return try await validation(value, req) ? nil : error
            }
        }
        return optional ? nil : error
    }
}
