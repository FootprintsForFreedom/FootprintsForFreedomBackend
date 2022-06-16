//
//  ApiRepositoryListUnverifiedDetailsController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryListUnverifiedDetailsController: RepositoryController {
    associatedtype ListUnverifiedDetailObject: Codable
    
    func beforeListUnverifiedDetails(_ req: Request) async throws
    func beforeGetUnverifiedDetail(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail>
    func listUnverifiedDetailsApi(_ req: Request) async throws -> Page<ListUnverifiedDetailObject>
    func listUnverifiedDetailsOutput(_ req: Request, _ repository: DatabaseModel, _ details: Page<Detail>) async throws -> Page<ListUnverifiedDetailObject>
    func listUnverifiedDetailsOutput(_ req: Request,  _ repository: DatabaseModel, _ detail: Detail) async throws -> ListUnverifiedDetailObject
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
            .filter(\._$status ~~ [.pending, .deleteRequested])
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
