//
//  ApiRepositoryUpdateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent
import AppApi

/// Streamlines updating repositories.
protocol ApiRepositoryUpdateController: DatabaseRepositoryController, UpdateController {
    /// The decodable update object.
    associatedtype UpdateObject: Decodable
    
    /// The ``AsyncValidator``s which need to be fulfilled before updating a repository.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before updating a repository.
    func updateValidators() -> [AsyncValidator]
    
    /// Validates the request and decodes the input.
    ///
    /// By default the request content is validated and the input decoded from there.
    ///
    /// - Parameter req: The request containing the input.
    /// - Returns: The decoded update object.
    func getUpdateInput(_ req: Request) async throws -> UpdateObject
    
    /// Processes the update input to create a new repository detail.
    /// - Parameters:
    ///   - req: The request on which to update the repository.
    ///   - repository: The already created repository to update.
    ///   - detail: The new detail to create.
    ///   - input: The update input.
    func updateInput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail, _ input: UpdateObject) async throws
    
    /// The update repository api action.
    /// - Parameter req: The request on which the repository is updated.
    /// - Returns: A response with the updated repository and detail.
    func updateApi(_ req: Request) async throws -> Response
    
    /// The repository detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the repository was updated.
    ///   - repository: The updated repository.
    ///   - detail: The updated detail.
    /// - Returns: The repository detail object to return as a response.
    func updateResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response
    
    /// Sets up the update repository routes.
    /// - Parameter routes: The routes on which to setup the update repository routes.
    func setupUpdateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryUpdateController {
    
    func updateValidators() -> [AsyncValidator] {
        []
    }
    
    func getUpdateInput(_ req: Request) async throws -> UpdateObject {
        try await RequestValidator(updateValidators()).validate(req)
        return try req.content.decode(UpdateObject.self)
    }
    
    func updateApi(_ req: Request) async throws -> Response {
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try await getUpdateInput(req)
        try await beforeUpdate(req, repository)
        let detail = Detail()
        try await updateInput(req, repository, detail, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository.update(on: req.db)
        try await repository._$details.create(detail, on: req.db)
        try await afterUpdate(req, repository)
        return try await updateResponse(req, repository, detail)
    }
    
    func setupUpdateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.put(use: updateApi)
    }
}
