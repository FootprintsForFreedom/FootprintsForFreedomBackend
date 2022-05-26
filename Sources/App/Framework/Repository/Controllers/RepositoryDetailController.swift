//
//  RepositoryDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryDetailController: RepositoryController {
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<Repository>) async throws -> QueryBuilder<Repository>
    func afterDetail(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> (Repository, Detail)
    func afterDetail(_ req: Request, _ repository: Repository) async throws -> Repository
    func detail(_ req: Request) async throws -> (Repository, Detail)
}

extension RepositoryDetailController {
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<Repository>) async throws -> QueryBuilder<Repository> {
        queryBuilder
    }
    
    func afterDetail(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> (Repository, Detail) {
        (repository, detail)
    }
    
    func afterDetail(_ req: Request, _ repository: Repository) async throws -> Repository {
        repository
    }
    
    func detail(_ req: Request) async throws -> (Repository, Detail) {
        let queryBuilder = Repository.query(on: req.db)
        let repository = try await beforeDetail(req, queryBuilder).filter(\._$id == identifier(req)).first()
        guard let repository = repository, let detail = try await repository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        return try await afterDetail(req, repository, detail)
    }
}
