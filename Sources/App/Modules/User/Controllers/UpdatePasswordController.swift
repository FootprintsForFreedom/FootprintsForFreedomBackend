//
//  UpdatePasswordController.swift
//  
//
//  UpdatePasswordd by niklhut on 31.01.22.
//

import Vapor

protocol UpdatePasswordController: ModelController {
    func beforeUpdatePassword(_ req: Request, _ model: DatabaseModel) async throws
    func afterUpdatePassword(_ req: Request, _ model: DatabaseModel) async throws
    
    func updatePassword(_ req: Request, _ model: DatabaseModel) async throws
}

extension UpdatePasswordController {
    
    func beforeUpdatePassword(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func afterUpdatePassword(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func updatePassword(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeUpdatePassword(req, model)
        try await model.update(on: req.db)
        try await afterUpdatePassword(req, model)
    }
}
