//
//  RepositoryPatchController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol RepositoryPatchController: RepositoryController {
    func beforePatch(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws
    func afterPatch(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws
    func patch(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws
}

extension RepositoryPatchController {
    func beforePatch(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws { }
    func afterPatch(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws { }
    func patch(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws {
        try await beforePatch(req, repository, object)
        if repository.hasChanges {
            try await repository.update(on: req.db)
        }
        try await object.create(on: req.db)
        try await afterPatch(req, repository, object)
    }
}
