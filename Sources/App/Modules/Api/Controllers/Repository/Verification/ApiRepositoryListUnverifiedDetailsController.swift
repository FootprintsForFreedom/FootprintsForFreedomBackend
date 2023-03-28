//
//  ApiRepositoryListUnverifiedDetailsController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines listing unverified details for a repository.
protocol ApiRepositoryListUnverifiedDetailsController: DatabaseRepositoryController {
    /// The codable list unverified detail object.
    associatedtype ListUnverifiedDetailObject: Codable
    
    /// Action performed prior to listing unverified details for a repository.
    /// - Parameter req: The request on which to find and return the unverified details.
    func beforeListUnverifiedDetails(_ req: Request) async throws
    
    /// Action performed prior to getting the unverified details.
    /// - Parameters:
    ///   - req: The request on which to load the details.
    ///   - queryBuilder: The `QueryBuilder` loading the details.
    /// - Returns: The potentially modified `QueryBuilder` loading the details.
    func beforeGetUnverifiedDetail(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail>
    
    /// The list unverified details api action.
    /// - Parameter req: The request on which to list the details.
    /// - Returns: A paged list of the unverified details for the repository.
    func listUnverifiedDetailsApi(_ req: Request) async throws -> Page<ListUnverifiedDetailObject>
    
    /// The list unverified details output.
    /// - Parameters:
    ///   - req: The request on which the details were loaded.
    ///   - repository: The repository for which the unverified details were requested.
    ///   - details: The unverified details to be returned.
    /// - Returns: A paged list of the unverified details for the repository.
    func listUnverifiedDetailsOutput(_ req: Request, _ repository: DatabaseModel, _ details: Page<Detail>) async throws -> Page<ListUnverifiedDetailObject>
    
    /// The list unverified detail output for one detail.
    /// - Parameters:
    ///   - req: The request on which the details were loaded.
    ///   - repository: The repository for which the unverified details were requested.
    ///   - detail: The unverified detail to be returned.
    /// - Returns: A detail object for the unverified detail.
    func listUnverifiedDetailsOutput(_ req: Request,  _ repository: DatabaseModel, _ detail: Detail) async throws -> ListUnverifiedDetailObject
    
    /// Sets up the list unverified details routes.
    /// - Parameter routes: The routes on which to setup the list unverified detail routes.
    func setupListUnverifiedDetailsRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryListUnverifiedDetailsController {
    func beforeListUnverifiedDetails(_ req: Request) async throws { }
    
    func beforeGetUnverifiedDetail(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder
    }
    
    func listUnverifiedDetailsApi(_ req: Request) async throws -> Page<ListUnverifiedDetailObject> {
        try await beforeListUnverifiedDetails(req)
        
        let repository = try await repository(req)
        
        let unverifiedDetailsQuery = repository._$details
            .query(on: req.db)
            .filter(\._$verifiedAt == nil)
        // only select details which have an active language
            .join(from: Detail.self, parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
            .sort(\._$updatedAt, .ascending) // oldest first
        
        let unverifiedDetails = try await beforeGetUnverifiedDetail(req, unverifiedDetailsQuery).paginate(for: req)
        
        return try await listUnverifiedDetailsOutput(req, repository, unverifiedDetails)
    }
    
    func listUnverifiedDetailsOutput(_ req: Request, _ repository: DatabaseModel, _ details: Page<Detail>) async throws -> Page<ListUnverifiedDetailObject> {
        return try await details
            .concurrentMap { detail in
                return try await listUnverifiedDetailsOutput(req, repository, detail)
            }
    }
    
    func setupListUnverifiedDetailsRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get("unverified", use: listUnverifiedDetailsApi)
    }
}
