//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public struct RequestValidator {
    
    public var validators: [AsyncValidator]
    
    public init(_ validators: [AsyncValidator]) {
        self.validators = validators
    }
    
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
    
//    public func isValid(_ req: Request) async -> Bool {
//        do {
//            try await validate(req, message: nil)
//            return true
//        }
//        catch {
//            return false
//        }
//    }
}
