//
//  RepositoryCreateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

protocol RepositoryCreateController: RepositoryController {
    func beforeCreate(_ req: Request, _ repository: Repository) async throws
    func afterCreate(_ req: Request, _ repository: Repository) async throws
    
    func create(_ req: Request, _ repository: Repository) async throws
}

extension RepositoryCreateController {
    func beforeCreate(_ req: Request, _ repository: Repository) async throws { }
    func afterCreate(_ req: Request, _ repository: Repository) async throws { }
    
    func create(_ req: Request, _ repository: Repository) async throws {
        try await beforeCreate(req, repository)
        try await repository.create(on: req.db)
        try await afterCreate(req, repository)
    }
}
