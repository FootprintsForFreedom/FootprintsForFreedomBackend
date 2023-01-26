//
//  ApiPatchController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import AppApi

/// Streamlines patching models.
protocol ApiPatchController: PatchController {
    /// The decodable patch object.
    associatedtype PatchObject: Decodable
    
    /// The ``AsyncValidator``s which need to be fulfilled before patching a model.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before patching a model.
    func patchValidators() -> [AsyncValidator]
    
    /// Processes the patch input to patch the model.
    /// - Parameters:
    ///   - req: The request on which to patch the model
    ///   - model: The model to patch.
    ///   - input: The patch input.
    func patchInput(_ req: Request, _ model: DatabaseModel, _ input: PatchObject) async throws
    
    /// The patch model api action.
    /// - Parameter req: The request on which the model is patched.
    /// - Returns: A response with the patched model.
    func patchApi(_ req: Request) async throws -> Response
    
    /// The model detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the model was patched.
    ///   - model: The patched model.
    /// - Returns: A response with the patched model.
    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    
    /// Sets up the patch model routes.
    /// - Parameter routes: The routes on which to setup the patch model routes.
    func setupPatchRoutes(_ routes: RoutesBuilder)
}

extension ApiPatchController {
    func patchValidators() -> [AsyncValidator] {
        []
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let model = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        try await patchInput(req, model, input)
        try await patch(req, model)
        return try await patchResponse(req, model)
    }
    
    func setupPatchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.patch(use: patchApi)
    }
}
