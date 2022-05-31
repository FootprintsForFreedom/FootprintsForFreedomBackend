//
//  ApiListRepositoriesWithUnverifiedDetailsController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiListRepositoriesWithUnverifiedDetailsController: RepositoryController {
    associatedtype RepositoriesWithUnverifiedDetailsResponseObject: Codable
    
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws
    func beforeGetRepositories(_ req: Request, _ queryBuilder: QueryBuilder<Repository>) async throws -> QueryBuilder<Repository>
    func listRepositoriesWithUnverifiedDetailsApi(_ req: Request) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject>
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repositories: Page<Repository>) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject>
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> RepositoriesWithUnverifiedDetailsResponseObject
    func setuplistRepositoriesWithUnverifiedDetailsRoutes(_ routes: RoutesBuilder)
}

extension ApiListRepositoriesWithUnverifiedDetailsController {
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws { }
    
    func beforeGetRepositories(_ req: Request, _ queryBuilder: QueryBuilder<Repository>) async throws -> QueryBuilder<Repository> {
        queryBuilder
        // only get unverified models
            .join(children: \._$details)
            .filter(Detail.self, \._$verified == false)
        // only select details which hava an active language
            .join(from: Detail.self, parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
        // only select the id field and return each id only once
            .field(\._$id)
            .unique()
    }
    
    func listRepositoriesWithUnverifiedDetailsApi(_ req: Request) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject> {
        try await beforeListRepositoriesWithUnverifiedDetails(req)
        
        let repositoriesWithUnverifiedModelsQuery = Repository.query(on: req.db)
        
        let repositoriesWithUnverifiedModels = try await beforeGetRepositories(req, repositoriesWithUnverifiedModelsQuery).paginate(for: req)
        
        return try await listRepositoriesWithUnverifiedDetailsOutput(req, repositoriesWithUnverifiedModels)
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repositories: Page<Repository>) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject> {
        let allLanguageCodesByPriority = try await req.allLanguageCodesByPriority()
        return try await repositories
            .concurrentMap { repository in
                guard let detail = try await repository.detail(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db) else {
                    throw Abort(.internalServerError)
                }
                return try await listRepositoriesWithUnverifiedDetailsOutput(req, repository, detail)
            }
    }
    
    func setuplistRepositoriesWithUnverifiedDetailsRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("unverified", use: listRepositoriesWithUnverifiedDetailsApi)
    }
}
