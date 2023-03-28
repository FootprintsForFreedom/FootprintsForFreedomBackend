//
//  ApiPagedListController.swift
//
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

/// Streamlines listing models in pages.
protocol ApiPagedListController: PagedListController {
    /// The list object content.
    associatedtype ListObject: Content
    
    /// The list output for a page of models.
    /// - Parameters:
    ///   - req: The request on which the models were fetched.
    ///   - models: The models to be in the output.
    /// - Returns: A paged list of list objects.
    func listOutput(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<ListObject>
    
    /// The paged list models api action.
    /// - Parameter req: The request on which to list the models.
    /// - Returns: A paged list of list objects.
    func listApi(_ req: Request) async throws -> Page<ListObject>
    
    /// Sets up the paged list models routes.
    /// - Parameter routes: The routes on which to setup the paged list models routes.
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiPagedListController {
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
