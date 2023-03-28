//
//  ApiRepositoryPatchController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent
import AppApi

/// Streamlines patching repositories.
protocol ApiRepositoryPatchController: DatabaseRepositoryController, PatchController {
    /// The decodable patch object.
    associatedtype PatchObject: Decodable
    
    /// The ``AsyncValidator``s which need to be fulfilled before patching a repository.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before patching a repository.
    func patchValidators() -> [AsyncValidator]
    
    /// Validates the request and decodes the input.
    ///
    /// By default the request content is validated and the input decoded from there.
    ///
    /// - Parameter req: The request containing the input.
    /// - Returns: The decoded patch object.
    func getPatchInput(_ req: Request) async throws -> PatchObject
    
    /// Processes the patch input to create a new repository detail.
    /// - Parameters:
    ///   - req: The request on which to patch the repository.
    ///   - repository: The already created repository to patch.
    ///   - detail: The new detail to create.
    ///   - input: The patch input.
    func patchInput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail, _ input: PatchObject) async throws
    
    /// The patch repository api action.
    /// - Parameter req: The request on which the repository is patched.
    /// - Returns: A response with the patched repository and detail.
    func patchApi(_ req: Request) async throws -> Response
    
    /// The repository detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the repository was patched.
    ///   - repository: The patched repository.
    ///   - detail: The patched detail.
    /// - Returns: A response with the patched repository and detail.
    func patchResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response
    
    /// Sets up the patch repository routes.
    /// - Parameter routes: The routes on which to setup the patch repository routes.
    func setupPatchRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryPatchController {
    func patchValidators() -> [AsyncValidator] {
        []
    }
    
    func getPatchInput(_ req: Request) async throws -> PatchObject {
        try await RequestValidator(patchValidators()).validate(req)
        return try req.content.decode(PatchObject.self)
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try await getPatchInput(req)
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
