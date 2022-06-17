//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Asynchronously validate a request
public protocol AsyncValidator {
    
    var key: String { get }
    var message: String { get }
    
    func validate(_ req: Request, _ validationObject: RequestValidationObject) async throws -> ValidationErrorDetail?
}

public extension AsyncValidator {
    
    var error: ValidationErrorDetail {
        .init(key: key, message: message)
    }
}

public enum RequestValidationObject {
    case content
    case query
}
