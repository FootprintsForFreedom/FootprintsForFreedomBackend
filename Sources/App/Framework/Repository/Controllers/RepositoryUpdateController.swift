//
//  RepositoryUpdateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

protocol RepositoryUpdateController: RepositoryController {
    func beforeUpdate(_ req: Request, _ repository: Repository) async throws
    func afterUpdate(_ req: Request, _ repository: Repository) async throws
    func update(_ req: Request, _ repository: Repository) async throws
}

extension RepositoryUpdateController {
    func beforeUpdate(_ req: Request, _ repository: Repository) async throws { }
    func afterUpdate(_ req: Request, _ repository: Repository) async throws { }
    
    func update(_ req: Request, _ repository: Repository) async throws {
        try await beforeUpdate(req, repository)
        try await repository.update(on: req.db)
        try await afterUpdate(req, repository)
    }
}
