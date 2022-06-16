//
//  ApiRepositoryDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryDetailController: RepositoryDetailController {
    associatedtype DetailObject: Content
    
    func detailOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> DetailObject
    func detailApi(_ req: Request) async throws -> DetailObject
    func detailBySlugApi(_ req: Request) async throws -> DetailObject
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
