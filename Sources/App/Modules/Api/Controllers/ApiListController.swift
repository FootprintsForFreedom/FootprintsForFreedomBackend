//
//  ApiListController.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

/// Streamlines listing models.
protocol ApiListController: ListController {
    /// The list object content.
    associatedtype ListObject: Content
    
    /// The list output for an array of models.
    /// - Parameters:
    ///   - req: The request on which the models were fetched.
    ///   - models: The models to be in the output.
    /// - Returns: An array of list objects.
    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [ListObject]
    
    /// The list models api action.,
    /// - Parameter req: The request on which to list the repositories.
    /// - Returns: An array of list objects.
    func listApi(_ req: Request) async throws -> [ListObject]
    
    /// Sets up the list models routes.
    /// - Parameter routes: The routes on which to setup the list models routes.
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiListController {
    func listApi(_ req: Request) async throws -> [ListObject] {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
