//
//  ApiEmailVerificationController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol ApiEmailVerificationController: VerificationController {
    associatedtype VerificationObject: Decodable
    
    func requestVerificationInput(_ req: Request, _ model: DatabaseModel) async throws
    func requestVerificationApi(_ req: Request) async throws -> HTTPStatus
    func requestVerificationResponse(_ req: Request, _ model: DatabaseModel) async throws -> HTTPStatus
    
    func verificationInput(_ req: Request, _ model: DatabaseModel, _ input: VerificationObject) async throws
    func verificationApi(_ req: Request) async throws -> Response
    func verificationResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    
    func setupVerificationRoutes(_ routes: RoutesBuilder)
}

extension ApiEmailVerificationController {
    func verificationApi(_ req: Request) async throws -> Response {
        /// Decode from query not content!
        let input = try req.query.decode(VerificationObject.self)
        let model = try await findBy(identifier(req), on: req.db)
        try await verificationInput(req, model, input)
        try await verification(req, model)
        return try await verificationResponse(req, model)
    }
    
    func requestVerificationApi(_ req: Request) async throws -> HTTPStatus {
        let model = try await findBy(identifier(req), on: req.db)
        try await requestVerificationInput(req, model)
        try await createVerification(req, model)
        return try await requestVerificationResponse(req, model)
    }
    
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        let verificationRoutes = existingModelRoutes.grouped("verify")
        let requestVerificationRoutes = existingModelRoutes
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped("requestVerification")
        verificationRoutes.post(use: verificationApi)
        requestVerificationRoutes.post(use: requestVerificationApi)
        // TODO: request route
    }
}
