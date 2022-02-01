//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol CreateController: ModelController {
    func beforeCreate(_ req: Request, _ model: DatabaseModel) async throws
    func afterCreate(_ req: Request, _ model: DatabaseModel) async throws
    
    func create(_ req: Request, _ model: DatabaseModel) async throws
}

extension CreateController {
    
    func beforeCreate(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func afterCreate(_ req: Request, _ model: DatabaseModel) async throws {}

    func create(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeCreate(req, model)
        try await model.create(on: req.db)
        try await afterCreate(req, model)
    }
}

