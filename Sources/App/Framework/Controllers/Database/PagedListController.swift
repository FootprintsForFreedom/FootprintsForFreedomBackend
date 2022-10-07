//
//  PagedListController.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

/// Streamlines paged loading of all ``DatabaseModelController/DatabaseModel``s of one Type from the database.
protocol PagedListController: DatabaseModelController {
    
    /// Action performed prior to getting models from the database.
    /// - Parameters:
    ///   - req: The `Request` on which the ``DatabaseModelController/DatabaseModel``s will be loaded.
    ///   - queryBuilder: The `QueryBuilder` which will be loading the ``DatabaseModelController/DatabaseModel``s.
    /// - Returns: The potentially modified `QueryBuilder` which will be loading the ``DatabaseModelController/DatabaseModel``s.
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel>
    
    /// Action performed after getting the models from the database.
    /// - Parameters:
    ///   - req: The `Request` on which the models were loaded.
    ///   - models: The loaded ``DatabaseModelController/DatabaseModel``s.
    /// - Returns: The page of the loaded and potentially modified ``DatabaseModelController/DatabaseModel``s.
    func afterList(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<DatabaseModel>
    
    /// Action performed to load all models of a type from the database in pages.
    ///
    /// This function should call ``beforeList(_:_:)`` prior to loading the models from the database and ``afterList(_:_:)``after loading the models from the database.
    /// - Parameter req: The `Request` on which the models should be loaded.
    /// - Returns: The page of  loaded ``DatabaseModelController/DatabaseModel``s.
    func list(_ req: Request) async throws -> Page<DatabaseModel>
}

extension PagedListController {
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
    }
    
    func afterList(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<DatabaseModel> {
        models
    }
    
    func list(_ req: Request) async throws -> Page<DatabaseModel> {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let list = try await beforeList(req, queryBuilder).paginate(for: req)
        return try await afterList(req, list)
    }
}
