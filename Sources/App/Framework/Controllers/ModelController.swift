//
//  ModelController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import AppApi

/// Streamlines controlling models.
public protocol ModelController {
    /// The api model.
    associatedtype ApiModel: ApiModelInterface
    
    /// Gets the model identifier from a request.
    /// - Parameter req: The request containing the model identifier.
    /// - Returns: The model `UUID`.
    func identifier(_ req: Request) throws -> UUID
    
    /// Gets the base routes for the model controller.
    /// - Parameter routes: The routes on which to register the model controller.
    /// - Returns: The model controller base routes.
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder
}

extension ModelController {
    func identifier(_ req: Request) throws -> UUID {
        guard
            let id = req.parameters.get(ApiModel.pathIdKey),
            let uuid = UUID(uuidString: id)
        else {
            throw Abort(.badRequest)
        }
        return uuid
    }
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped(ApiModel.Module.pathKey.pathComponents)
            .grouped(ApiModel.pathKey.pathComponents)
    }
}
