//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

protocol ApiListController: ListController {
    associatedtype ListObject: Content

    func listOutput(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<ListObject>
    func listApi(_ req: Request) async throws -> Page<ListObject>
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiListController {
    
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}

