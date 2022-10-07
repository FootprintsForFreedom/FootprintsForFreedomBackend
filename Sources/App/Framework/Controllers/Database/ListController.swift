//
//  ListController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

/// Streamlines loading all ``DatabaseModelController/DatabaseModel``s of one Type from the database.
protocol ListController: DatabaseModelController {
    
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
    /// - Returns: The potentially modified array of loaded ``DatabaseModelController/DatabaseModel``s.
    func afterList(_ req: Request, _ models: [DatabaseModel]) async throws -> [DatabaseModel]
    
    /// Action performed to load all models of a type from the database.
    ///
    /// This function should call ``beforeList(_:_:)`` prior to loading the models from the database and ``afterList(_:_:)``after loading the models from the database.
    /// - Parameter req: The `Request` on which the models should be loaded.
    /// - Returns: The array of  loaded ``DatabaseModelController/DatabaseModel``s.
    func list(_ req: Request) async throws -> [DatabaseModel]

}

extension ListController {
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
    }
    
    func afterList(_ req: Request, _ models: [DatabaseModel]) async throws -> [DatabaseModel] {
        models
    }
    
    func list(_ req: Request) async throws -> [DatabaseModel] {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let list = try await beforeList(req, queryBuilder).all()
        return try await afterList(req, list)
    }
}
