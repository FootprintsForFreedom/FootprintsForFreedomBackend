//
//  ApiElasticPagedListController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import Fluent

/// Streamlines listing models in pages from elasticsearch.
protocol ApiElasticPagedListController: ElasticPagedListController {
    /// The list object content.
    associatedtype ListObject: Content
    
    /// The detail output for a page of repositories.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repositories: The repositories to be in the output.
    /// - Returns: A paged list of list objects.
    func listOutput(_ req: Request, _ models: Page<ElasticModel>) async throws -> Page<ListObject>
    
    /// The detail output for one repository.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repository: The repository to be in the output.
    /// - Returns: A list object of the repository and detail.
    func listOutput(_ req: Request, _ model: ElasticModel) async throws -> ListObject
    
    /// The list repositories api action.
    /// - Parameter req: The request on which to list the repositories.
    /// - Returns: A paged list of the repositories.
    func listApi(_ req: Request) async throws -> Page<ListObject>
    
    /// Sets up the list repository routes.
    /// - Parameter routes: The routes on which to setup the list repository routes.
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiElasticPagedListController {
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func listOutput(_ req: Request, _ models: Page<ElasticModel>) async throws -> Page<ListObject> {
        try await models.concurrentCompactMap { model in
            try await listOutput(req, model)
        }
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
