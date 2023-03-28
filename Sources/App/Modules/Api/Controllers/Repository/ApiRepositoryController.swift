//
//  ApiRepositoryController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines controlling repositories.
protocol ApiRepositoryController:
    ApiRepositoryDetailController,
    ApiRepositoryPagedListController,
    ApiRepositoryCreateController,
    ApiRepositoryUpdateController,
    ApiRepositoryPatchController,
    ApiDeleteController
{
    /// The ``AsyncValidator``s which need to be fulfilled before creating, updating or patching a repository.
    /// - Parameter optional: Wether or not the validator is required.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled to create update or patch the repository.
    func validators(optional: Bool) -> [AsyncValidator]
    
    /// Sets up the repository routes.
    /// - Parameter routes: The routes on which so setup the repository routes.
    func setupRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryController {
    func validators(optional: Bool) -> [AsyncValidator] {
        []
    }
    
    func createValidators() -> [AsyncValidator] {
        validators(optional: false)
    }
    
    func updateValidators() -> [AsyncValidator] {
        validators(optional: false)
    }
    
    func patchValidators() -> [AsyncValidator] {
        validators(optional: true)
    }
    
    func createResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(status: .created, for: req)
    }
    
    func updateResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }
    
    func patchResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        setupDetailRoutes(routes)
        setupListRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
}
