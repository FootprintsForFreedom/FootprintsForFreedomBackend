//
//  ValidationAbort.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Error thrown when the validation fails.
public struct ValidationAbort: AbortError {
    /// The abort error
    public var abort: Abort
    /// The error message  sent with the failed validation.
    public var message: String?
    /// The  additional``ValidationErrorDetail``s.
    public var details: [ValidationErrorDetail]
    
    /// The reason for the validation abort.
    public var reason: String { abort.reason }
    /// The status code for the validation abort.
    public var status: HTTPStatus { abort.status }
    
    /// Initialize the validation abort with all parameters.
    /// - Parameters:
    ///   - abort: The abort error.
    ///   - message: The error message sent with the failed validation.
    ///   - details: The additional ``ValidationErrorDetail``s.
    public init(abort: Abort, message: String? = nil, details: [ValidationErrorDetail]) {
        self.abort = abort
        self.message = message
        self.details = details
    }
}
