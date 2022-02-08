//
//  ApiDetailOwnUserController.swift
//  
//
//  Created by niklhut on 04.02.22.
//

import Vapor

protocol ApiDetailOwnUserController: DetailController {
    associatedtype DetailObject: Content
    
    func detailOwnUserInput(_ req: Request) async throws -> DatabaseModel
    func detailOwnUserOutput(_ req: Request, _ model: DatabaseModel) async throws -> DetailObject
    func detailOwnUserApi(_ req: Request) async throws -> DetailObject
    func setupDetailOwnUserRoutes(_ routes: RoutesBuilder)
}

extension ApiDetailOwnUserController {

    func detailOwnUserApi(_ req: Request) async throws -> DetailObject {
        let model = try await detailOwnUserInput(req)
        return try await detailOwnUserOutput(req, model)
    }
    
    func setupDetailOwnUserRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped("me")
        existingModelRoutes.get(use: detailOwnUserApi)
    }
}

