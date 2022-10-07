//
//  DatabaseModelController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

/// Streamlines controlling database models.
public protocol DatabaseModelController: ModelController {
    /// The database model.
    associatedtype DatabaseModel: DatabaseModelInterface
    
    /// The module name.
    static var moduleName: String { get }
    
    /// Finds a model by its id on the database.
    /// - Parameters:
    ///   - id: The model id.
    ///   - on: The database on which to find the model.
    /// - Returns: The database model with the given id.
    func findBy(_ id: UUID, on: Database) async throws -> DatabaseModel
}

extension DatabaseModelController {
    public static var moduleName: String { DatabaseModel.Module.identifier.capitalized }
    
    func findBy(_ id: UUID, on db: Database) async throws -> DatabaseModel {
        guard let model = try await DatabaseModel.find(id, on: db) else {
            throw Abort(.notFound)
        }
        return model
    }
}
