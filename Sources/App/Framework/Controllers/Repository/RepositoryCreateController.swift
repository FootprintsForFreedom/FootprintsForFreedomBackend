//
//  RepositoryCreateController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol RepositoryCreateController: RepositoryController {
    func beforeCreateRepository(_ req: Request, _ repository: DatabaseModel) async throws
    func afterCreateRepository(_ req: Request, _ repository: DatabaseModel) async throws
    
    func createRepository(_ req: Request, _ repository: DatabaseModel) async throws
    
    func beforeCreateObject(_ req: Request, _ object: ObjectModel) async throws
    func afterCreateObject(_ req: Request, _ object: ObjectModel) async throws
    
    func createObject(_ req: Request, _ object: ObjectModel) async throws
}

extension RepositoryCreateController {
    func beforeCreateRepository(_ req: Request, _ repository: DatabaseModel) async throws { }
    func afterCreateRepository(_ req: Request, _ repository: DatabaseModel) async throws { }
    
    func createRepository(_ req: Request, _ repository: DatabaseModel) async throws {
        try await beforeCreateRepository(req, repository)
        try await repository.create(on: req.db)
        try await afterCreateRepository(req, repository)
    }
    
    func beforeCreateObject(_ req: Request, _ object: ObjectModel) async throws { }
    func afterCreateObject(_ req: Request, _ object: ObjectModel) async throws { }
    
    func createObject(_ req: Request, _ object: ObjectModel) async throws {
        try await beforeCreateObject(req, object)
        try await object.create(on: req.db)
        try await afterCreateObject(req, object)
    }
}
