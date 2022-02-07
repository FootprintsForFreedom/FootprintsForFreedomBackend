//
//  ChangeRoleController.swift
//  
//
//  Created by niklhut on 07.02.22.
//

import Vapor

protocol ChangeRoleController: ModelController {
    func beforeChangeRole(_ req: Request, _ model: DatabaseModel) async throws
    func afterChangeRole(_ req: Request, _ model: DatabaseModel) async throws
    
    func changeRole(_ req: Request, _ model: DatabaseModel) async throws
}

extension ChangeRoleController {
    func beforeChangeRole(_ req: Request, _ model: DatabaseModel) async throws {}
    func afterChangeRole(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func changeRole(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeChangeRole(req, model)
        try await model.update(on: req.db)
        try await afterChangeRole(req, model)
    }
}
