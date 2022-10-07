//
//  DatabaseRepositoryController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import Fluent

protocol DatabaseRepositoryController: RepositoryController, DatabaseModelController where DatabaseModel: RepositoryModel, DatabaseModel.Detail.Repository == DatabaseModel {
    /// The database detail model.
    typealias Detail = DatabaseModel.Detail
    
    /// Finds a detail by its slug on the database.
    /// - Parameters:
    ///   - slug: The detail slug.
    ///   - on: The database on which to find the detail model.
    /// - Returns: The detail model with the given slug.
    func findBy(_ slug: String, on db: Database) async throws -> Detail
    
    /// Gets a repository from a request.
    /// - Parameter req: The request of which to get the repository model.
    /// - Returns: The repository model given in the request.
    func repository(_ req: Request) async throws -> DatabaseModel
}

extension DatabaseRepositoryController where DatabaseModel: Reportable  {
    /// The database report model.
    typealias Report = DatabaseModel.Report
}

extension DatabaseRepositoryController {
    func findBy(_ slug: String, on db: Database) async throws -> Detail {
        guard let detail = try await Detail
            .query(on: db)
            .filter(\._$slug == slug)
            .first()
        else {
            throw Abort(.notFound)
        }
        return detail
    }
    
    func repository(_ req: Request) async throws -> DatabaseModel {
        return try await findBy(identifier(req), on: req.db)
    }
}
