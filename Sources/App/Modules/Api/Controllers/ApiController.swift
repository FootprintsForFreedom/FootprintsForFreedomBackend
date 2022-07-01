//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol ApiControllerWithoutList:
    ApiDetailController,
    ApiCreateController,
    ApiUpdateController,
    ApiPatchController,
    ApiDeleteController
{
    func validators(optional: Bool) -> [AsyncValidator]
    
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
