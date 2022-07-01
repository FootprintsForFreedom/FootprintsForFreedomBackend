//
//  ApiRepositoryVerifyDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines verifying a detail controller.
protocol ApiRepositoryVerifyDetailController: RepositoryController {
    /// The detail object content.
    associatedtype DetailObject: Content
    
    /// The path id key for the new model.
    var newModelPathIdKey: String { get }
    /// The path id component for the new model.
    var newModelPathIdComponent: PathComponent { get }
    
    /// Action performed prior to verifying a detail.
    /// - Parameter req: The request on which to verify the detail.
    func beforeVerifyDetail(_ req: Request) async throws
    
    /// Action performed prior to getting the detail to verify.
    /// - Parameters:
    ///   - req: The request on which to load the detail to verify.
    ///   - queryBuilder: The `QueryBuilder` loading the detail to verify.
    /// - Returns: The potentially modified `QueryBuilder` loading the detail to verify.
    func beforeGetDetailToVerify(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail>
    
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
    
    func beforeGetDetailToVerify(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder
    }
    
    func verifyDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws {
        if let previousDetail = try await repository.detail(for: detail.language.languageCode, needsToBeVerified: true, on: req.db) {
            previousDetail.slug = try await previousDetail.generateSlug(with: .day, on: req.db)
            try await previousDetail.update(on: req.db)
        }
        detail.slug = try await detail.generateSlug(with: .none, on: req.db)
        detail.status = .verified
        try await detail.update(on: req.db)
    }
    
    func verifyDetailApi(_ req: Request) async throws -> DetailObject {
        try await beforeVerifyDetail(req)
        
        let repository = try await repository(req)
        
        guard
            let detailIdString = req.parameters.get(newModelPathIdKey),
            let detailtId = UUID(uuidString: detailIdString)
        else {
            throw Abort(.badRequest)
        }
        
        let detailQuery = try Detail
            .query(on: req.db)
            .filter(\._$id == detailtId)
            .filter(\._$repository.$id == repository.requireID())
            .filter(\._$status ~~ [.pending, .deleteRequested])
            .with(\._$language)
        
        guard let detail = try await beforeGetDetailToVerify(req, detailQuery).first() else {
            throw Abort(.badRequest)
        }
        
        try await verifyDetail(req, repository, detail)
        
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
