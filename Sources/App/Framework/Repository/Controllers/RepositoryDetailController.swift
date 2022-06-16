//
//  RepositoryDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryDetailController: RepositoryController {
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel>
    func afterDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> (DatabaseModel, Detail)
    func afterDetail(_ req: Request, _ repository: DatabaseModel) async throws -> DatabaseModel
    func detail(_ req: Request) async throws -> (DatabaseModel, Detail)
}

extension RepositoryDetailController {
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
    }
    
    func afterDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> (DatabaseModel, Detail) {
        (repository, detail)
    }
    
    func afterDetail(_ req: Request, _ repository: DatabaseModel) async throws -> DatabaseModel {
        repository
    }
    
    func detail(_ req: Request) async throws -> (DatabaseModel, Detail) {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let repository = try await beforeDetail(req, queryBuilder).filter(\._$id == identifier(req)).first()
        guard let repository = repository, let detail = try await repository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        return try await afterDetail(req, repository, detail)
    }
}
