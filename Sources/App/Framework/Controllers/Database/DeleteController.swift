//
//  DeleteController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines deleting ``DatabaseModelController/DatabaseModel``s from the database
public protocol DeleteController: DatabaseModelController {
    /// Action performed prior to deleting model from database.
    /// - Parameters:
    ///   - req: The `Request` on which the model will be deleted.
    ///   - model: The ``DatabaseModelController/DatabaseModel``whichthat wil be deleted.
    func beforeDelete(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed after deleting model from database.
    /// - Parameters:
    ///   - req: The `Request` on which the model was deleted.
    ///   - model: The deleted ``DatabaseModelController/DatabaseModel``.
    func afterDelete(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed to delete model from database.
    ///
    /// This function should call ``beforeDelete(_:_:)`` prior to deleting the model from the database and ``afterDelete(_:_:)`` after deleting the model from the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model should be deleted.
    ///   - model: The ``DatabaseModelController/DatabaseModel`` which should be deleted.
    func delete(_ req: Request, _ model: DatabaseModel) async throws
}

extension DeleteController {
    
    func beforeDelete(_ req: Request, _ model: DatabaseModel) async throws {}
    func afterDelete(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func delete(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforeDelete(req, model)
        try await model.delete(on: req.db)
        try await afterDelete(req, model)
    }
}
