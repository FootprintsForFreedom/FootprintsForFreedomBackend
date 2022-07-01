//
//  ApiController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines controlling models.
///
/// This protocol does not include a list functionality.
protocol ApiControllerWithoutList:
    ApiDetailController,
    ApiCreateController,
    ApiUpdateController,
    ApiPatchController,
    ApiDeleteController
{
    /// The ``AsyncValidator``s which need to be fulfilled before creating, updating or patching a model.
    /// - Parameter optional: Wether or not the validator is required.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled to create update or patch the model.
    func validators(optional: Bool) -> [AsyncValidator]
    
    /// Sets up the model routes.
    /// - Parameter routes: The routes on which to setup the model routes.
    func setupRoutes(_ routes: RoutesBuilder)
}

extension ApiControllerWithoutList {
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
    
    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(status: .created, for: req)
    }
    
    func updateResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
}

/// Streamlines controlling models.
///
/// This protocol includes a paged list functionality.
protocol ApiController: ApiPagedListController, ApiControllerWithoutList { }

extension ApiController {
    func setupRoutes(_ routes: RoutesBuilder) {
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
}

/// Streamlines controlling models.
///
/// This protocol includes an unpaged list functionality.
protocol UnpagedApiController: ApiListController, ApiControllerWithoutList { }

extension UnpagedApiController {
    func setupRoutes(_ routes: RoutesBuilder) {
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
}
