//
//  ApiRepositoryPatchController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryPatchController: RepositoryController, PatchController {
    associatedtype PatchObject: Decodable
    
    func patchValidators() -> [AsyncValidator]
    func getPatchInput(_ req: Request) throws -> PatchObject
    func patchInput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail, _ input: PatchObject) async throws
    func patchApi(_ req: Request) async throws -> Response
    func patchResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response
}

extension ApiRepositoryPatchController {
    func patchValidators() -> [AsyncValidator] {
        []
    }
    
    func getPatchInput(_ req: Request) throws -> PatchObject {
        try req.content.decode(PatchObject.self)
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try getPatchInput(req)
        try await beforePatch(req, repository)
        let detail = Detail()
        try await patchInput(req, repository, detail, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository.update(on: req.db)
        try await repository._$details.create(detail, on: req.db)
        return try await patchResponse(req, repository, detail)
    }
    
    func setupPatchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.patch(use: patchApi)
    }
}
