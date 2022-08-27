//
//  RepositoryDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines getting single ``RepositoryModel``s from the database.
protocol RepositoryDetailController: RepositoryController {
    
    /// Action performed prior to getting a repository from the database.
    /// - Parameters:
    ///   - req: The `Request` on which the repository will be loaded from the database.
    ///   - queryBuilder: The `QueryBuilder` which will be loading the ``RepositoryModel``.
    /// - Returns: The  potentially modified `QueryBuilder` which will be loading the ``RepositoryModel``.
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel>
    
    /// Action performed after getting the model form the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model was loaded.
    ///   - repository: The loaded ``RepositoryModel``.
    ///   - detail: The loaded ``DetailModel``.
    /// - Returns: The potentially modified ``RepositoryModel``.
    func afterDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> (DatabaseModel, Detail)
    
    /// Action performed to load a model from the database.
    ///
    /// This function should call ``beforeDetail(_:_:)`` prior to loading the model from the database and ``afterDetail(_:_:)``after loading the model from the database.
    /// - Parameter req: The `Request` on which the model should be loaded.
    /// - Returns: The ``RepositoryModel`` which was loaded.
    func detail(_ req: Request) async throws -> (DatabaseModel, Detail)
}

extension RepositoryDetailController {
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
    }
    
    func afterDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> (DatabaseModel, Detail) {
        (repository, detail)
    }
    
    func detail(_ req: Request) async throws -> (DatabaseModel, Detail) {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let repository = try await beforeDetail(req, queryBuilder).filter(\._$id == identifier(req)).first()
        guard let repository = repository, let detail = try await repository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        return try await afterDetail(req, repository, detail)
    }
}
