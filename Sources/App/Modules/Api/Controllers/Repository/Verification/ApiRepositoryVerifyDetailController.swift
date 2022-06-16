//
//  ApiRepositoryVerifyDetailController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryVerifyDetailController: RepositoryController {
    associatedtype DetailObject: Content
    
    var newModelPathIdKey: String { get }
    var newModelPathIdComponent: PathComponent { get }
    
    func beforeVerifyDetail(_ req: Request) async throws
    func beforeGetDetailToVerify(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail>
    func verifyDetail(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws
    func verifyDetailApi(_ req: Request) async throws -> DetailObject
    func verifyDetailOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> DetailObject
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
