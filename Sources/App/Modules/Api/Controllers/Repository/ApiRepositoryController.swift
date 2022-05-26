//
//  ApiRepositoryController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryController:
    ApiRepositoryDetailController,
    ApiRepositoryPagedListController,
    ApiRepositoryCreateController,
    ApiRepositoryUpdateController,
    ApiRepositoryPatchController,
    ApiRepositoryDeleteController
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
    
    func createResponse(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(status: .created, for: req)
    }
    
    func updateResponse(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }
    
    func patchResponse(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> Response {
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
