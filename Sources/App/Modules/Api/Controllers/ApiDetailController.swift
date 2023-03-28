//
//  ApiDetailController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import AppApi

/// Streamlines detailing a model.
protocol ApiDetailController: DetailController {
    /// The detail object content.
    associatedtype DetailObject: Content
    
    /// The detail output for a model.
    /// - Parameters:
    ///   - req: The request on which  to detail the model.
    ///   - model: The model to be detailed.
    /// - Returns: The model detail object.
    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> DetailObject
    
    /// The detail api action.
    /// - Parameter req: The request on which to detail the model.
    /// - Returns: The model detail object.
    func detailApi(_ req: Request) async throws -> DetailObject
    
    /// Sets up the model detail routes.
    /// - Parameter routes: The routes on which to setup the model detail routes.
    func setupDetailRoutes(_ routes: RoutesBuilder)
}

extension ApiDetailController {
    func detailApi(_ req: Request) async throws -> DetailObject {
        let model = try await detail(req)
        return try await detailOutput(req, model)
    }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get(use: detailApi)
    }
}
