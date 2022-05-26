//
//  ApiRepositoryDetailChangesController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryDetailChangesController: RepositoryController {
    associatedtype DetailChangesResponseObject: Content
    
    func detailChangesValidators() -> [AsyncValidator]
    func beforeDetailChanges(_ req: Request) async throws
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail>
    func detailChangesApi(_ req: Request) async throws -> DetailChangesResponseObject
    func detailChangesOutput(_ req: Request, _ model1: Detail, _ model2: Detail) async throws -> DetailChangesResponseObject
    func setupDetailChangesRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryDetailChangesController {
    @AsyncValidatorBuilder
    func detailChangesValidators() -> [AsyncValidator] {
        KeyedContentValidator<UUID>.required("from", validateQuery: true)
        KeyedContentValidator<UUID>.required("to", validateQuery: true)
    }
    
    func beforeDetailChanges(_ req: Request) async throws { }
    
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder
    }
    
    func detailChangesApi(_ req: Request) async throws -> DetailChangesResponseObject {
        try await beforeDetailChanges(req)
        
        try await RequestValidator(detailChangesValidators()).validate(req)
        let input = try req.query.decode(DetailChangesObject.self)
        let repository = try await repository(req)
        
        let model1QueryBuilder = try Detail.query(on: req.db)
            .filter(\._$repository.$id == repository.requireID())
            .filter(\._$id == input.from)
        let model2QueryBuilder = try Detail.query(on: req.db)
            .filter(\._$repository.$id == repository.requireID())
            .filter(\._$id == input.to)
        
        guard
            let model1 = try await beforeGetDetailModel(req, model1QueryBuilder).first(),
            let model2 = try await beforeGetDetailModel(req, model2QueryBuilder).first()
        else {
            throw Abort(.notFound)
        }
        
        guard model1._$language.id == model2._$language.id else {
            throw Abort(.badRequest, reason: "The models need to be of the same language")
        }
        
        return try await detailChangesOutput(req, model1, model2)
    }
    
    func setupDetailChangesRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get("changes", use: detailChangesApi)
    }
}
