//
//  PatchController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines patching ``DatabaseModelController/DatabaseModel``s on the database.
protocol PatchController: DatabaseModelController {
    
    /// Action performed prior to patching a model on the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model will be patched.
    ///   - model: The ``DatabaseModelController/DatabaseModel`` which will be patched.
    func beforePatch(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed after patching a model on the database.
    /// - Parameters:
    ///   - req: The `Reqeust` on which the model was patched.
    ///   - model: The patched ``DatabaseModelController/DatabaseModel``.
    func afterPatch(_ req: Request, _ model: DatabaseModel) async throws
    
    /// Action performed to patch a model on the database.
    ///
    /// This function should call ``beforePatch(_:_:)`` prior to patching the model on the database and ``afterPatch(_:_:)`` after patching the model on the database.
    /// - Parameters:
    ///   - req: The `Request` on which the model should be patched.
    ///   - model: The ``DatabaseModelController/DatabaseModel`` which should be patched.
    func patch(_ req: Request, _ model: DatabaseModel) async throws
}

extension PatchController {
    func beforePatch(_ req: Request, _ model: DatabaseModel) async throws {}
    func afterPatch(_ req: Request, _ model: DatabaseModel) async throws {}
    
    func patch(_ req: Request, _ model: DatabaseModel) async throws {
        try await beforePatch(req, model)
        try await model.update(on: req.db)
        try await afterPatch(req, model)
    }
}
