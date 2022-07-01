//
//  CreateController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines creating ``ModelController/DatabaseModel``s to the database.
protocol CreateController: ModelController {
    
    /// Action performed prior to saving model to database.
    /// - Parameters:
    ///   - req: The `Request` on which the model will be created.
    ///   - model: The ``ModelController/DatabaseModel`` which will be created.
    func beforeCreate(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed after saving model to database.
    /// - Parameters:
    ///   - req: The `Request` on which the model was created.
    ///   - model: The created ``ModelController/DatabaseModel``.
    func afterCreate(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed to save model to database.
    ///
    /// This function should call ``beforeCreate(_:_:)`` prior to saving the model to the database and ``afterCreate(_:_:)`` after creating the model to the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model should be created.
    ///   - model: The ``ModelController/DatabaseModel`` which should be created.
    func create(_ req: Request, _ model: DatabaseModel) async throws
}

extension CreateController {
    
    func beforeCreate(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func afterCreate(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func create(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeCreate(req, model)
        try await model.create(on: req.db)
        try await afterCreate(req, model)
    }
}

