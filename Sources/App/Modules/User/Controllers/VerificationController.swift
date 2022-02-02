//
//  VerificationController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol VerificationController: ModelController {
    func beforeVerification(_ req: Request, _ model: DatabaseModel) async throws
    func afterVerification(_ req: Request, _ model: DatabaseModel) async throws
    
    func verification(_ req: Request, _ model: DatabaseModel) async throws
}

extension VerificationController {
    
    func beforeVerification(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func afterVerification(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func verification(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeVerification(req, model)
        try await model.update(on: req.db)
        try await afterVerification(req, model)
    }
}
