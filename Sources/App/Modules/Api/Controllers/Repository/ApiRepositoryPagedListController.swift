//
//  ApiRepositoryPagedListController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryPagedListController: RepositoryPagedListController {
    associatedtype ListObject: Content
    
    func listOutput(_ req: Request, _ repositories: Page<Repository>) async throws -> Page<ListObject>
    func listOutput(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> ListObject
    func listApi(_ req: Request) async throws -> Page<ListObject>
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryPagedListController {
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let repositories = try await list(req)
        return try await listOutput(req, repositories)
    }
    
    func listOutput(_ req: Request, _ repositories: Page<Repository>) async throws -> Page<ListObject> {
        return try await repositories
            .concurrentMap { repository in
                // get a detail model for the repository
                guard let detail = try await repository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
                    return nil
                }
                return try await listOutput(req, repository, detail)
            }
            .compactMap { $0 } // remove all nil values
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
