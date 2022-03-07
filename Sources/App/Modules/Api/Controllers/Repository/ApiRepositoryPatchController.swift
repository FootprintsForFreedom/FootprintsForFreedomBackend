//
//  ApiRepositoryPatchController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol ApiRepositoryPatchController: RepositoryPatchController {
    associatedtype PatchObject: Decodable
    
    func patchValidators() -> [AsyncValidator]
    func patchInput(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel, _ input: PatchObject) async throws
    func patchApi(_ req: Request) async throws -> Response
    func patchResponse(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws -> Response
    func setupPatchRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryPatchController {
    func patchValidators() -> [AsyncValidator] {
        []
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        let object = ObjectModel()
        try await patchInput(req, repository, object, input)
        try await patch(req, repository, object)
        return try await patchResponse(req, repository, object)
    }
    
    func setupPatchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.patch(use: patchApi)
    }
}
