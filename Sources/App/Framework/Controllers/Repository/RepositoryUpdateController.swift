//
//  RepositoryUpdateController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol RepositoryUpdateController: RepositoryController {
    func beforeUpdate(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws
    func afterUpdate(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws
    
    func update(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws
}

extension RepositoryUpdateController {
    func beforeUpdate(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws { }
    func afterUpdate(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws { }
    
    func update(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws {
        try await beforeUpdate(req, repository, object)
        if repository.hasChanges {
            try await repository.update(on: req.db)
        }
        try await object.create(on: req.db)
        try await afterUpdate(req, repository, object)
    }
}
