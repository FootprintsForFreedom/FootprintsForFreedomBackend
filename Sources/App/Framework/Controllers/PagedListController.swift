//
//  PagedListController.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

protocol PagedListController: ModelController {
    
    func list(_ req: Request) async throws -> Page<DatabaseModel>
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel>
    func afterList(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<DatabaseModel>
}

extension PagedListController {
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<DatabaseModel>) async throws -> QueryBuilder<DatabaseModel> {
        queryBuilder
    }
    
    func afterList(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<DatabaseModel> {
        models
    }
    
    func list(_ req: Request) async throws -> Page<DatabaseModel> {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let list = try await beforeList(req, queryBuilder).paginate(for: req)
        return try await afterList(req, list)
    }
}
