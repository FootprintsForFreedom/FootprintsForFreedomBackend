//
//  ApiRepositoryController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol ApiRepositoryController: ApiListController,
                                  ApiRepositoryDetailController,
                                  ApiRepositoryCreateController,
                                  ApiRepositoryUpdateController,
                                  ApiRepositoryPatchController,
                                  ApiDeleteController
{
    func validators(optional: Bool) -> [AsyncValidator]
    
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
    
    func createResponse(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws -> Response {
        try await detailOutput(req, repository, object).encodeResponse(status: .created, for: req)
    }
    
    func updateResponse(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws -> Response {
        try await detailOutput(req, repository, object).encodeResponse(for: req)
    }
    
    func patchResponse(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws -> Response {
        try await detailOutput(req, repository, object).encodeResponse(for: req)
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
}
