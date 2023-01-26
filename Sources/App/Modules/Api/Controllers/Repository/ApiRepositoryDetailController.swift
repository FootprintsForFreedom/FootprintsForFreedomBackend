//
//  ApiRepositoryDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent
import AppApi

/// Streamlines detailing a repository.
protocol ApiRepositoryDetailController: RepositoryDetailController {
    /// The detail object content.
    associatedtype DetailObject: Content
    
    /// The detail output for a repository.
    /// - Parameters:
    ///   - req: The request on which to detail the repository.
    ///   - repository: The repository to be detailed.
    ///   - detail: The detail to be returned with the repository.
    /// - Returns: The repository detail object.
    func detailOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> DetailObject
    
    /// The detail api action.
    /// - Parameter req: The request on which to detail the repository.
    /// - Returns: The repository detail object.
    func detailApi(_ req: Request) async throws -> DetailObject
    
    /// The detail by slug api action.
    ///
    /// Instead of finding the repository by its id this function searches the unique slugs of the details to find the requested repository detail.
    ///
    /// - Parameter req: The request on which to detail the repository.
    /// - Returns: The repository detail object.
    func detailBySlugApi(_ req: Request) async throws -> DetailObject
    
    /// Sets up the detail repository routes.
    /// - Parameter routes: The routes on which to setup the detail repository routes.
    func setupDetailRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryDetailController {
    func detailApi(_ req: Request) async throws -> DetailObject {
        let (repository, detail) = try await detail(req)
        return try await detailOutput(req, repository, detail)
    }
    
    func detailBySlugApi(_ req: Request) async throws -> DetailObject {
        let detail = try await findBy(slug(req), on: req.db)
        try await detail._$repository.load(on: req.db)
        return try await detailOutput(req, detail.repository, detail)
    }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get(use: detailApi)
        
        let slugRoutes = baseRoutes.grouped("find").grouped(ApiModel.pathIdComponent)
        slugRoutes.get(use: detailBySlugApi)
    }
}
