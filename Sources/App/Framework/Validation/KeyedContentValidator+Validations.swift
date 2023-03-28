//
//  KeyedContentValidator+Validations.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public extension KeyedContentValidator where T == String {
    /// Requires a non empty string to be present.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func required(_ key: String, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is required", optional: optional) { value, _ in !value.isEmpty }
    }
    
    /// Requires a string with a minimum amount of characters.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - length: The required minimum length of the string.
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func min(_ key: String, _ length: Int, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too short (min: \(length) characters)", optional: optional) { value, _ in value.count >= length }
    }
    
    /// Requires a string with a maximum amount of characters.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - length: The required maximum length of the string.
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func max(_ key: String, _ length: Int, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too long (max: \(length) characters)", optional: optional) { value, _ in value.count <= length }
    }
    
    /// Requires a string consisting of **only** alphanumerics to be present.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func alphanumeric(_ key: String, _ message: String? = nil, _ optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) should be only alphanumeric characters", optional: optional) { value, _ in
            !Validator.characterSet(.alphanumerics).validate(value).isFailure
        }
    }
    
    /// Requires a string in the form of an email to be present.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func email(_ key: String, _ message: String? = nil, _ optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) should be a valid email address", optional: optional) { value, _ in
            !Validator.email.validate(value).isFailure
        }
    }
}

public extension KeyedContentValidator where T == Int {
    /// Requires an int with a minimum value.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - minValue: The required minimum value.
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func min(_ key: String, _ minValue: Int, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too small (min: \(minValue))", optional: optional) { value, _ in value >= minValue }
    }
    
    /// Requires an int with a maximum value.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - maxValue: The required maximum value.
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func max(_ key: String, _ maxValue: Int, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too big (max: \(maxValue))", optional: optional) { value, _ in value <= maxValue }
    }
    
    /// Requires an int within the given values.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - values: The values which must contain the int.
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func contains(_ key: String, _ values: [Int], _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is an invalid value", optional: optional) { value, _ in values.contains(value) }
    }
}

public extension KeyedContentValidator {
    /// Requires a the key to be present and contain any value.
    /// - Parameters:
    ///   - key: The key at which to find the value to validate
    ///   - message: The error message sent when the validation fails.
    ///   - optional: Wether or not this field is required.
    /// - Returns: The ``KeyedContentValidator`` with the given parameters.
    static func required(_ key: String, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is required", optional: optional) { _, _ in true }
    }
}
