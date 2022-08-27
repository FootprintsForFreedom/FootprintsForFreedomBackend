//
//  ApiRepositoryPagedListController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines listing repositories in pages.
protocol ApiRepositoryPagedListController: RepositoryController, PagedListController  {
    /// The list object content.
    associatedtype ListObject: Content
    
    /// The detail output for a page of repositories.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repositories: The repositories to be in the output.
    /// - Returns: A paged list of list objects.
    func listOutput(_ req: Request, _ repositories: Page<DatabaseModel>) async throws -> Page<ListObject>
    
    /// The detail output for one repository.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repository: The repository to be in the output.
    ///   - detail: The detail to be in the output.
    /// - Returns: A list object of the repository and detail.
    func listOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> ListObject
    
    /// The list repositories api action.
    /// - Parameter req: The request on which to list the repositories.
    /// - Returns: A paged list of the repositories.
    func listApi(_ req: Request) async throws -> Page<ListObject>
    
    /// Sets up the list repository routes.
    /// - Parameter routes: The routes on which to setup the list repository routes.
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryPagedListController {
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let repositories = try await list(req)
        return try await listOutput(req, repositories)
    }
    
    func listOutput(_ req: Request, _ repositories: Page<DatabaseModel>) async throws -> Page<ListObject> {
        return try await repositories
            .concurrentCompactMap { repository in
                // get a detail model for the repository
                guard let detail = try await repository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
                    return nil
                }
                return try await listOutput(req, repository, detail)
            }
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
