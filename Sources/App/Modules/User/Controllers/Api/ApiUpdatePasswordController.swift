//
//  ApiUpdatePasswordController.swift
//  
//
//  Created by niklhut on 31.01.22.
//

import Vapor

protocol ApiUpdatePasswordController: UpdatePasswordController {
    associatedtype UpdatePasswordObject: Decodable
    
    func updatePasswordValidators() -> [AsyncValidator]
    func updatePasswordInput(_ req: Request, _ model: DatabaseModel, _ input: UpdatePasswordObject) async throws
    func updatePasswordApi(_ req: Request) async throws -> Response
    func updatePasswordResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    func setupUpdatePasswordRoutes(_ routes: RoutesBuilder)
}

extension ApiUpdatePasswordController {
    func updatePasswordValidators() -> [AsyncValidator] {
        []
    }
    
    func updatePasswordApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updatePasswordValidators()).validate(req)
        let input = try req.content.decode(UpdatePasswordObject.self)
        let model = try await findBy(identifier(req), on: req.db)
        try await updatePasswordInput(req, model, input)
        try await updatePassword(req, model)
        return try await updatePasswordResponse(req, model)
    }
    
    func setupUpdatePasswordRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped(ApiModel.pathIdComponent).grouped("updatePassword")
        existingModelRoutes.put(use: updatePasswordApi)
    }
}
