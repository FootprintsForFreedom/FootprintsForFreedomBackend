//
//  ModelController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

public protocol ModelController {
    /// The api model.
    associatedtype ApiModel: ApiModelInterface
    /// The database model.
    associatedtype DatabaseModel: DatabaseModelInterface
    
    /// The module name.
    static var moduleName: String { get }
    
    /// Gets the model identifier from a request.
    /// - Parameter req: The request containing the model identifier.
    /// - Returns: The model `UUID`.
    func identifier(_ req: Request) throws -> UUID
    
    /// Finds a model by its id on the database.
    /// - Parameters:
    ///   - id: The model id.
    ///   - on: The database on which to find the model.
    /// - Returns: The database model with the given id.
    func findBy(_ id: UUID, on: Database) async throws -> DatabaseModel
    
    /// Gets the base routes for the model controller.
    /// - Parameter routes: The routes on which to register the model controller.
    /// - Returns: The model controller base routes.
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder
}

extension ModelController {
    static var moduleName: String { DatabaseModel.Module.identifier.capitalized }
    
    func identifier(_ req: Request) throws -> UUID {
        guard
            let id = req.parameters.get(ApiModel.pathIdKey),
            let uuid = UUID(uuidString: id)
        else {
            throw Abort(.badRequest)
        }
        return uuid
    }
    
    func findBy(_ id: UUID, on db: Database) async throws -> DatabaseModel {
        guard let model = try await DatabaseModel.find(id, on: db) else {
            throw Abort(.notFound)
        }
        return model
    }
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped(ApiModel.Module.pathKey.pathComponents)
            .grouped(ApiModel.pathKey.pathComponents)
    }
}

