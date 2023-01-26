//
//  ApiUpdateController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import AppApi

/// Streamlines updating models.
protocol ApiUpdateController: UpdateController {
    /// The decodable update object.
    associatedtype UpdateObject: Decodable
    
    /// The ``AsyncValidator``s which need to be fulfilled before updating a model.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before updating a model.
    func updateValidators() -> [AsyncValidator]
    
    /// Processes the update input to update the model.
    /// - Parameters:
    ///   - req: The request on which to update the model.
    ///   - model: The model to be updated.
    ///   - input: The update input.
    func updateInput(_ req: Request, _ model: DatabaseModel, _ input: UpdateObject) async throws
    
    /// The update model api action.
    /// - Parameter req: The request on which the model is updated.
    /// - Returns: A response containing the updated model.
    func updateApi(_ req: Request) async throws -> Response
    
    /// The model detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the model was updated.
    ///   - model: The updated model.
    /// - Returns: A response containing the updated model.
    func updateResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    
    /// Sets up the update model routes.
    /// - Parameter routes: The routes on which to setup the update model routes.
    func setupUpdateRoutes(_ routes: RoutesBuilder)
}

extension ApiUpdateController {
    func updateValidators() -> [AsyncValidator] {
        []
    }
    
    func updateApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updateValidators()).validate(req)
        let model = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(UpdateObject.self)
        try await updateInput(req, model, input)
        try await update(req, model)
        return try await updateResponse(req, model)
    }
    
    func setupUpdateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.put(use: updateApi)
    }
}
