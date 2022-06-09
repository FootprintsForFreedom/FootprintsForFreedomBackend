//
//  RepositoryController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryController where Repository.Detail.Repository == Repository {
    associatedtype ApiModel: ApiModelInterface
    associatedtype Repository: RepositoryModel
    typealias Detail = Repository.Detail
    
    static var moduleName: String { get }
    static var modelName: Name { get }
    
    func identifier(_ req: Request) throws -> UUID
    func slug(_ req: Request) throws -> String
    func findBy(_ id: UUID, on: Database) async throws -> Repository
    func findBy(_ slug: String, on: Database) async throws -> Detail
    func repository(_ req: Request) async throws -> Repository
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder
}

extension RepositoryController where Repository: Reportable {
    typealias Report = Repository.Report
}

extension RepositoryController {
    static var moduleName: String { Repository.Module.identifier.capitalized }
    static var modelName: Name { .init(singular: String(Repository.identifier.dropLast(1))) }
    
    func identifier(_ req: Request) throws -> UUID {
        guard
            let id = req.parameters.get(ApiModel.pathIdKey),
            let uuid = UUID(uuidString: id)
        else {
            throw Abort(.badRequest)
        }
        return uuid
    }
    
    func slug(_ req: Request) throws -> String {
        guard
            let slug = req.parameters.get(ApiModel.pathIdKey),
            slug == slug.slugify()
        else {
            throw Abort(.badRequest)
        }
        return slug
    }
    
    func findBy(_ id: UUID, on db: Database) async throws -> Repository {
        guard let repository = try await Repository.find(id, on: db) else {
            throw Abort(.notFound)
        }
        return repository
    }
    
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
    
    func repository(_ req: Request) async throws -> Repository {
        return try await findBy(identifier(req), on: req.db)
    }
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped(ApiModel.Module.pathKey.pathComponents)
            .grouped(ApiModel.pathKey.pathComponents)
    }
}
