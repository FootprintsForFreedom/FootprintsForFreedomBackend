//
//  RepositoryPatchController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

protocol RepositoryPatchController: RepositoryController {
    func beforePatch(_ req: Request, _ repository: Repository) async throws
    func afterPatch(_ req: Request, _ repository: Repository) async throws
    func patch(_ req: Request, _ repository: Repository) async throws
}

extension RepositoryPatchController {
    func beforePatch(_ req: Request, _ repository: Repository) async throws { }
    func afterPatch(_ req: Request, _ repository: Repository) async throws { }
    
    func patch(_ req: Request, _ repository: Repository) async throws {
        try await beforePatch(req, repository)
        try await repository.update(on: req.db)
        try await afterPatch(req, repository)
    }
}
