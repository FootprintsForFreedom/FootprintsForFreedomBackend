//
//  RepositoryController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryController: ModelController where DatabaseModel: RepositoryModel, DatabaseModel.Detail.Repository == DatabaseModel {
    typealias Detail = DatabaseModel.Detail
    
    func slug(_ req: Request) throws -> String
    func findBy(_ slug: String, on db: Database) async throws -> Detail
    func repository(_ req: Request) async throws -> DatabaseModel
}

extension RepositoryController where DatabaseModel: Reportable  {
    typealias Report = DatabaseModel.Report
}

extension RepositoryController {
    func slug(_ req: Request) throws -> String {
        guard
            let slug = req.parameters.get(ApiModel.pathIdKey),
            slug == slug.slugify()
        else {
            throw Abort(.badRequest)
        }
        return slug
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
    
    func repository(_ req: Request) async throws -> DatabaseModel {
        return try await findBy(identifier(req), on: req.db)
    }
}
