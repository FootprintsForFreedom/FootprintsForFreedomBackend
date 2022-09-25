//
//  ApiRepositoryVerifyDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines verifying a detail object.
protocol ApiRepositoryVerifyDetailController: DatabaseRepositoryController {
    /// The detail object content.
    associatedtype DetailObject: Content
    
    /// The path id key for the new model.
    var newModelPathIdKey: String { get }
    /// The path id component for the new model.
    var newModelPathIdComponent: PathComponent { get }
    
    /// Action performed prior to verifying a detail.
    /// - Parameter req: The request on which to verify the detail.
    func beforeVerifyDetail(_ req: Request) async throws
    
    /// Verifies the detail on the database.
    /// - Parameters:
    ///   - req: The request on which to verify the detail.
    ///   - repository: The repository to which the detail belongs.
    ///   - detail: The detail to be verified.
    func verifyDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws
    
    /// The verify detail api action.
    /// - Parameter req: The request on which to verify the detail.
    /// - Returns: A detail object for the verified detail.
    func verifyDetailApi(_ req: Request) async throws -> DetailObject
    
    // TODO: documenttaion
    func afterVerifyDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws
    
    /// The output for the verified detail.
    /// - Parameters:
    ///   - req: The request on which the detail was verified.
    ///   - repository: The repository to which the detail belongs.
    ///   - detail: The detail which was verified.
    /// - Returns: A detail object for the verified detail.
    func verifyDetailOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> DetailObject
    
    /// Sets up the verify detail routes.
    /// - Parameter routes: The routes on which to setup the verify detail routes.
    func setupVerifyDetailRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryVerifyDetailController {
    var newModelPathIdKey: String { "newModel" }
    var newModelPathIdComponent: PathComponent { .init(stringLiteral: ":" + newModelPathIdKey) }
    
    func beforeVerifyDetail(_ req: Request) async throws { }
    func afterVerifyDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws { }
    
    func verifyDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws {
        guard detail.language.priority != nil else {
            throw Abort(.badRequest)
        }
        
        if let previousDetail = try await repository._$details.firstFor(detail.language.languageCode, needsToBeVerified: true, on: req.db) {
            previousDetail.slug = try await previousDetail.generateSlug(with: .day, on: req.db)
            try await previousDetail.update(on: req.db)
        }
        detail.slug = try await detail.generateSlug(with: .none, on: req.db)
        detail.verifiedAt = Date()
        try await detail.update(on: req.db)
    }
    
    func verifyDetailApi(_ req: Request) async throws -> DetailObject {
        try await beforeVerifyDetail(req)
        
        let repository = try await repository(req)
        
        guard
            let detailIdString = req.parameters.get(newModelPathIdKey),
            let detailId = UUID(uuidString: detailIdString),
            let detail = try await Detail
                .query(on: req.db)
                .filter(\._$id == detailId)
                .filter(\._$repository.$id == repository.requireID())
                .filter(\._$verifiedAt == nil)
                .with(\._$language)
                .first()
        else {
            throw Abort(.badRequest)
        }
        
        try await verifyDetail(req, repository, detail)
        try await afterVerifyDetail(req, repository, detail)
        
        return try await verifyDetailOutput(req, repository, detail)
    }
    
    func setupVerifyDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.grouped("verify")
            .grouped(newModelPathIdComponent)
            .post(use: verifyDetailApi)
    }
}
