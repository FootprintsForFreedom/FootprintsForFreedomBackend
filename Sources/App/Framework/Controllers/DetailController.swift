//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

/// Streamlines getting single ``ModelController/DatabaseModel``s from the database.
protocol DetailController: ModelController {
    
    /// Action performed prior to getting a model from the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model will be loaded from the database.
    ///   - queryBuilder: The `QueryBuilder` which will be loading the ``ModelController/DatabaseModel``.
    /// - Returns: The  potentially modified `QueryBuilder` which will be loading the ``ModelController/DatabaseModel``.
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel>
    
    /// Action performed after getting the model from the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model was loaded.
    ///   - model: The  loaded ``ModelController/DatabaseModel``.
    /// - Returns: The potentially modified ``ModelController/DatabaseModel``.
    func afterDetail(_ req: Request, _ model: DatabaseModel) async throws -> DatabaseModel
    
    /// Action performed to load a model from the database.
    ///
    /// This function should call ``beforeDetail(_:_:)`` prior to loading the model from the database and ``afterDetail(_:_:)``after loading the model from the database.
    /// - Parameter req: The `Request` on which the model should be loaded.
    /// - Returns: The ``ModelController/DatabaseModel`` which was loaded.
    func detail(_ req: Request) async throws -> DatabaseModel
}

extension DetailController {
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
    }
    
    func afterDetail(_ req: Request, _ model: DatabaseModel) async throws -> DatabaseModel {
        model
    }
    
    func detail(_ req: Request) async throws -> DatabaseModel {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let model = try await beforeDetail(req, queryBuilder).filter(\._$id == identifier(req)).first()
        guard let model = model else {
            throw Abort(.notFound)
        }
        return try await afterDetail(req, model)
    }

}
