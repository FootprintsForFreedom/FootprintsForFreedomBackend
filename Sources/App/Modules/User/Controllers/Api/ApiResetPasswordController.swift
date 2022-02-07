//
//  ApiResetPasswordController.swift
//  
//
//  Created by niklhut on 03.02.22.
//

import Vapor

protocol ApiResetPasswordController: VerificationController {
    associatedtype ResetPasswordObject: Decodable
    associatedtype ResetPasswordRequestObject: Decodable
    
    func requestResetPasswordValidators() -> [AsyncValidator]
    func requestResetPasswordInput(_ req: Request, _ input: ResetPasswordRequestObject) async throws -> DatabaseModel
    func requestResetPasswordApi(_ req: Request) async throws -> HTTPStatus
    func requestResetPasswordResponse(_ req: Request, _ model: DatabaseModel) async throws -> HTTPStatus
    
    func resetPasswordValidators() -> [AsyncValidator]
    func resetPasswordInput(_ req: Request, _ model: DatabaseModel, _ input: ResetPasswordObject) async throws
    func resetPasswordApi(_ req: Request) async throws -> Response
    func resetPasswordResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    
    func setupResetPasswordRoutes(_ routes: RoutesBuilder)
}

extension ApiResetPasswordController {
    func resetPasswordValidators() -> [AsyncValidator] {
        []
    }
    
    func resetPasswordApi(_ req: Request) async throws -> Response {
        try await RequestValidator(resetPasswordValidators()).validate(req)
        let input = try req.content.decode(ResetPasswordObject.self)
        let model = try await findBy(identifier(req), on: req.db)
        try await resetPasswordInput(req, model, input)
        try await verification(req, model)
        return try await resetPasswordResponse(req, model)
    }
    
    func requestResetPasswordValidators() -> [AsyncValidator] {
        []
    }
    
    func requestResetPasswordApi(_ req: Request) async throws -> HTTPStatus {
        try await RequestValidator(requestResetPasswordValidators()).validate(req)
        let input = try req.content.decode(ResetPasswordRequestObject.self)
//        let model = try await findBy(identifier(req), on: req.db)
        let model = try await requestResetPasswordInput(req, input)
        try await createVerification(req, model)
        return try await requestResetPasswordResponse(req, model)
    }
    
    func setupResetPasswordRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        let resetPasswordRoutes = existingModelRoutes.grouped("resetPassword")
        let requestResetPasswordRoutes = baseRoutes.grouped("resetPassword")
        resetPasswordRoutes.post(use: resetPasswordApi)
        requestResetPasswordRoutes.post(use: requestResetPasswordApi)
    }
}
