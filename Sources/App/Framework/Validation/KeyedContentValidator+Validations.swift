//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public extension KeyedContentValidator where T == String {
    static func required(_ key: String, _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is required", optional: optional, validateQuery: validateQuery) { value, _ in !value.isEmpty }
    }
    
    static func min(_ key: String, _ length: Int, _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too short (min: \(length) characters)", optional: optional, validateQuery: validateQuery) { value, _ in value.count >= length }
    }
    
    static func max(_ key: String, _ length: Int, _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too long (max: \(length) characters)", optional: optional, validateQuery: validateQuery) { value, _ in value.count <= length }
    }
    
    static func alphanumeric(_ key: String, _ message: String? = nil, _ optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) should be only alphanumeric characters", optional: optional, validateQuery: validateQuery) { value, _ in
            !Validator.characterSet(.alphanumerics).validate(value).isFailure
        }
    }
    
    static func email(_ key: String, _ message: String? = nil, _ optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) should be a valid email address", optional: optional, validateQuery: validateQuery) { value, _ in
            !Validator.email.validate(value).isFailure
        }
    }
}

public extension KeyedContentValidator where T == Int {
    static func min(_ key: String, _ length: Int, _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too short (min: \(length) characters)", optional: optional, validateQuery: validateQuery) { value, _ in value >= length }
    }
    
    static func max(_ key: String, _ length: Int, _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is too long (max: \(length) characters)", optional: optional, validateQuery: validateQuery) { value, _ in value <= length }
    }
    
    static func contains(_ key: String, _ values: [Int], _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is an invalid value", optional: optional, validateQuery: validateQuery) { value, _ in values.contains(value) }
    }
}

public extension KeyedContentValidator {
    static func required(_ key: String, _ message: String? = nil, optional: Bool = false, validateQuery: Bool = false) -> KeyedContentValidator<T> {
        .init(key, message ?? "\(key.capitalized) is required", optional: optional, validateQuery: validateQuery) { _, _ in true }
    }
}
