//
//  ApiPagedListController.swift
//
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

protocol ApiPagedListController: PagedListController {
    associatedtype ListObject: Content
    
    func listOutput(_ req: Request, _ models: Page<DatabaseModel>) async throws -> Page<ListObject>
    func listApi(_ req: Request) async throws -> Page<ListObject>
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiPagedListController {
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
