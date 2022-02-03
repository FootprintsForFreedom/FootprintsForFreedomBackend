//
//  VerificationController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol VerificationController: ModelController {
    
    func beforeCreateVerification(_ req: Request, _ model: DatabaseModel) async throws
    func afterCreateVerification(_ req: Request, _ model: DatabaseModel) async throws
    
    func createVerification(_ req: Request, _ model: DatabaseModel) async throws
    
    
    func beforeVerification(_ req: Request, _ model: DatabaseModel) async throws
    func afterVerification(_ req: Request, _ model: DatabaseModel) async throws
    
    func verification(_ req: Request, _ model: DatabaseModel) async throws
}

extension VerificationController {
    
    func beforeCreateVerification(_ req: Request, _ model: DatabaseModel) async throws {}
    func afterCreateVerification(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func createVerification(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeCreateVerification(req, model)
        try await model.update(on: req.db)
        try await afterCreateVerification(req, model)
    }
    
    
    func beforeVerification(_ req: Request, _ model: DatabaseModel) async throws {}
    func afterVerification(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func verification(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeVerification(req, model)
        try await model.update(on: req.db)
        try await afterVerification(req, model)
    }
}
