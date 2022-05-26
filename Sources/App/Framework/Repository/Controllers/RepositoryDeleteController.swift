//
//  RepositoryDeleteController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

protocol RepositoryDeleteController: RepositoryController {
    func beforeDelete(_ req: Request, _ repository: Repository) async throws
    func afterDelete(_ req: Request, _ repository: Repository) async throws
    func delete(_ req: Request, _ repository: Repository) async throws
}

extension RepositoryDeleteController {
    func beforeDelete(_ req: Request, _ repository: Repository) async throws {}
    func afterDelete(_ req: Request, _ repository: Repository) async throws {}
    
    func delete(_ req: Request, _ repository: Repository) async throws {
        try await beforeDelete(req, repository)
        try await repository.delete(on: req.db)
        try await afterDelete(req, repository)
    }
}
