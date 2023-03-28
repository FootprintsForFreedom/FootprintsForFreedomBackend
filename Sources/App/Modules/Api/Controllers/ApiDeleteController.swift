//
//  ApiDeleteController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import AppApi

/// Streamlines deleting models.
protocol ApiDeleteController: DeleteController {
    
    /// The delete model api action.
    /// - Parameter req: The request on which to delete the model.
    /// - Returns: An `HTTPStatus` confirming the deletion of the model.
    func deleteApi(_ req: Request) async throws -> HTTPStatus
    
    /// Sets up the model delete routes.
    /// - Parameter routes: The routes on which to setup the model delete routes.
    func setupDeleteRoutes(_ routes: RoutesBuilder)
}

extension ApiDeleteController {
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let model = try await findBy(identifier(req), on: req.db)
        try await delete(req, model)
        return .noContent
    }
    
    func setupDeleteRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.delete(use: deleteApi)
    }
}
