//
//  ApiListRepositoriesWithUnverifiedDetailsController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines listing repositories with unverified details.
protocol ApiListRepositoriesWithUnverifiedDetailsController: DatabaseRepositoryController {
    /// The codable repository with unverified detail response object.
    associatedtype RepositoriesWithUnverifiedDetailsResponseObject: Codable
    
    /// Action performed prior to listing repositories with unverified details.
    /// - Parameter req: The request on which to find and return the repositories with unverified details.
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws
    
    /// Action performed prior to getting the repositories.
    /// - Parameters:
    ///   - req: The request on which to load the repositories.
    ///   - queryBuilder: The `QueryBuilder` loading the repositories.
    /// - Returns: The potentially modified `QueryBuilder` loading the repositories.
    func beforeGetRepositories(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel>
    
    /// The list repositories with unverified detail api action.
    /// - Parameter req: The request on which to list the repositories with unverified details.
    /// - Returns: A paged list of the repository detail object for the repositories with unverified details.
    func listRepositoriesWithUnverifiedDetailsApi(_ req: Request) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject>
    
    /// The list repositories with unverified details output.
    /// - Parameters:
    ///   - req: The request on which the repositories were loaded.
    ///   - repositories: The repositories with unverified details.
    /// - Returns: A paged list of the repository detail object for the repositories with unverified details.
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repositories: Page<DatabaseModel>) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject>
    
    /// The output for one repository with containing at least one unverified detail.
    /// - Parameters:
    ///   - req: The request on which the repositories were loaded.
    ///   - repository: The repository with at least one unverified detail.
    ///   - detail: A detail object for the repository. This detail object is verified, if a verified detail is available otherwise it is unverified.
    /// - Returns: A detail object for the repository.
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> RepositoriesWithUnverifiedDetailsResponseObject
    
    /// Sets up the list repositories with unverified details routes.
    /// - Parameter routes: The routes on which to setup the list repositories with unverified details routes.
    func setupListRepositoriesWithUnverifiedDetailsRoutes(_ routes: RoutesBuilder)
}

extension ApiListRepositoriesWithUnverifiedDetailsController {
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws { }
    
    func beforeGetRepositories(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
        // only get unverified models
            .join(children: \._$details)
            .filter(Detail.self, \._$verifiedAt == nil)
        // only select details which have an active language
            .join(from: Detail.self, parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
        // only select the id field and return each id only once
            .field(\._$id)
            .unique()
    }
    
    func listRepositoriesWithUnverifiedDetailsApi(_ req: Request) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject> {
        try await beforeListRepositoriesWithUnverifiedDetails(req)
        
        let repositoriesWithUnverifiedModelsQuery = DatabaseModel.query(on: req.db)
        
        let repositoriesWithUnverifiedModels = try await beforeGetRepositories(req, repositoriesWithUnverifiedModelsQuery).paginate(for: req)
        
        return try await listRepositoriesWithUnverifiedDetailsOutput(req, repositoriesWithUnverifiedModels)
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repositories: Page<DatabaseModel>) async throws -> Page<RepositoriesWithUnverifiedDetailsResponseObject> {
        let allLanguageCodesByPriority = try await req.allLanguageCodesByPriority()
        return try await repositories
            .concurrentMap { repository in
                guard let detail = try await repository._$details.firstFor(allLanguageCodesByPriority, needsToBeVerified: false, on: req.db) else {
                    throw Abort(.internalServerError)
                }
                return try await listRepositoriesWithUnverifiedDetailsOutput(req, repository, detail)
            }
    }
    
    func setupListRepositoriesWithUnverifiedDetailsRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("unverified", use: listRepositoriesWithUnverifiedDetailsApi)
    }
}
