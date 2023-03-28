//
//  ApiCreateController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines creating models.
protocol ApiCreateController: CreateController {
    /// The decodable create object.
    associatedtype CreateObject: Decodable
    
    /// The ``AsyncValidator``s which need to be fulfilled before creating a model.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before creating a model.
    func createValidators() -> [AsyncValidator]
    
    /// Processes the create input to create a model.
    /// - Parameters:
    ///   - req: The request on which to create the detail.
    ///   - model: The new model.
    ///   - input: The create input.
    func createInput(_ req: Request, _ model: DatabaseModel, _ input: CreateObject) async throws
    
    /// The create model api action.
    /// - Parameter req: The request on which the model is created.
    /// - Returns: A response containing the created model.
    func createApi(_ req: Request) async throws -> Response
    
    /// The model detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the model was created.
    ///   - model: The created model.
    /// - Returns: A response containing the created model.
    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    
    /// Sets up the create model routes.
    /// - Parameter routes: The routes on which to setup the create model routes.
    func setupCreateRoutes(_ routes: RoutesBuilder)
}

extension ApiCreateController {
    func createValidators() -> [AsyncValidator] {
        []
    }
    
    func createApi(_ req: Request) async throws -> Response {
        try await RequestValidator(createValidators()).validate(req)
        let input = try req.content.decode(CreateObject.self)
        let model = DatabaseModel()
        try await createInput(req, model, input)
        try await create(req, model)
        return try await createResponse(req, model)
    }
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.post(use: createApi)
    }
}
