//
//  ApiRepositoryDeleteController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryDeleteController: RepositoryDeleteController {
    func deleteApi(_ req: Request) async throws -> HTTPStatus
    func setupDeleteRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryDeleteController {
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let repository = try await findBy(identifier(req), on: req.db)
        try await delete(req, repository)
        return .noContent
    }
    
    func setupDeleteRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.delete(use: deleteApi)
    }
}
