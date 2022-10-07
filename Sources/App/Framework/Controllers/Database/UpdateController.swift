//
//  UpdateController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines updating ``DatabaseModelController/DatabaseModel``s on the database.
protocol UpdateController: DatabaseModelController {
    
    /// Action performed prior to updating a model on the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model will be updated.
    ///   - model: The ``DatabaseModelController/DatabaseModel`` which will be updated.
    func beforeUpdate(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed after updating a model on the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model was updated.
    ///   - model: The updated ``DatabaseModelController/DatabaseModel``.
    func afterUpdate(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed to update model on the database.
    ///
    /// This function should call ``beforeUpdate(_:_:)`` prior to updating the model on the database and ``afterUpdate(_:_:)`` after updating the model on the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model should be updated
    ///   - model: The ``DatabaseModelController/DatabaseModel`` which should be updated
    func update(_ req: Request, _ model: DatabaseModel) async throws
}

extension UpdateController {
    
    func beforeUpdate(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func afterUpdate(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func update(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeUpdate(req, model)
        try await model.update(on: req.db)
        try await afterUpdate(req, model)
    }
}
