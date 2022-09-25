//
//  ApiRepositoryCreateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines creating repositories-
protocol ApiRepositoryCreateController: DatabaseRepositoryController, CreateController {
    /// The decodable create object.
    associatedtype CreateObject: Decodable
    
    /// The ``AsyncValidator``s which need to be fulfilled before creating a repository.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before creating a repository.
    func createValidators() -> [AsyncValidator]
    
    /// Validates the request and decodes the input.
    ///
    /// By default the request content is validated and the input decoded from there.
    ///
    /// - Parameter req: The request containing the input.
    /// - Returns: The decoded create object.
    func getCreateInput(_ req: Request) async throws -> CreateObject
    
    /// Processes the create input to create a repository.
    /// - Parameters:
    ///   - req: The request on which to create the repository.
    ///   - repository: The new repository.
    ///   - input: The create input.
    func createRepositoryInput(_ req: Request, _ repository: DatabaseModel, _ input: CreateObject) async throws
    
    /// Processes the create input to create a repository detail.
    /// - Parameters:
    ///   - req: The request on which to create the detail.
    ///   - repository: The already created repository.
    ///   - detail: The new detail.
    ///   - input: The create input.
    func createInput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail, _ input: CreateObject) async throws
    
    /// The create repository api action.
    /// - Parameter req: The request on which the repository is created.
    /// - Returns: A response containing the created repository and detail.
    func createApi(_ req: Request) async throws -> Response
    
    /// The repository detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the repository was created.
    ///   - repository: The created repository.
    ///   - detail: The created detail.
    /// - Returns: A response containing the created repository and detail.
    func createResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response
    
    /// Sets up the create repository routes.
    /// - Parameter routes: The routes on which to setup the create repository routes.
    func setupCreateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryCreateController {
    func createValidators() -> [AsyncValidator] {
        []
    }
    
    func getCreateInput(_ req: Request) async throws -> CreateObject {
        try await RequestValidator(createValidators()).validate(req)
        return try req.content.decode(CreateObject.self)
    }
    
    func createRepositoryInput(_ req: Request, _ repository: DatabaseModel, _ input: CreateObject) async throws { }
    
    func createApi(_ req: Request) async throws -> Response {
        let input = try await getCreateInput(req)
        let repository = DatabaseModel()
        try await createRepositoryInput(req, repository, input)
        try await create(req, repository)
        let detail = Detail()
        try await createInput(req, repository, detail, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository._$details.create(detail, on: req.db)
        return try await createResponse(req, repository, detail)
    }
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.post(use: createApi)
    }
}
