//
//  ApiChangeRoleController.swift
//  
//
//  Created by niklhut on 07.02.22.
//

import Vapor

protocol ApiChangeRoleController: ChangeRoleController {
    associatedtype ChangeRoleObject: Decodable
    
    func changeRoleValidators() -> [AsyncValidator]
    func changeRoleInput(_ req: Request, _ model: DatabaseModel, _ input: ChangeRoleObject) async throws
    func changeRoleApi(_ req: Request) async throws -> Response
    func changeRoleResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    func setupChangeRoleRoutes(_ routes: RoutesBuilder)
}

extension ApiChangeRoleController {
    func changeRoleValidators() -> [AsyncValidator] {
        []
    }
    
    func changeRoleApi(_ req: Request) async throws -> Response {
        try await RequestValidator(changeRoleValidators()).validate(req)
        let input = try req.content.decode(ChangeRoleObject.self)
        let model = try await findBy(identifier(req), on: req.db)
        try await changeRoleInput(req, model, input)
        try await changeRole(req, model)
        return try await changeRoleResponse(req, model)
    }
    
    func setupChangeRoleRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped(ApiModel.pathIdComponent)
            .grouped("changeRole")
        existingModelRoutes.put(use: changeRoleApi)
    }
}
