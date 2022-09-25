//
//  ApiRepositoryDetailChangesController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// Streamlines detailing changes for repository detail models.
protocol ApiRepositoryDetailChangesController: DatabaseRepositoryController {
    /// The detail changes object content.
    associatedtype DetailChangesResponseObject: Content
    
    /// The ``AsyncValidator``s which need to be fulfilled to detail the changes.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled to detail the changes.
    func detailChangesValidators() -> [AsyncValidator]
    
    /// Action performed prior to detailing the changes.
    /// - Parameter req: The request on which to detail the changes.
    func beforeDetailChanges(_ req: Request) async throws
    
    /// Action performed prior to loading a detail model.
    /// - Parameters:
    ///   - req: The request on which the detail model is loaded.
    ///   - queryBuilder: The `QueryBuilder` loading the detail.
    /// - Returns: The potentially modified `QueryBuilder` loading the detail.
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail>
    
    /// The detail changes api action.
    /// - Parameter req: The request on which to detail the changes.
    /// - Returns: The detail changes object.
    func detailChangesApi(_ req: Request) async throws -> DetailChangesResponseObject
    
    /// Creates the output detailing the changes.
    /// - Parameters:
    ///   - req: The request on which the details were loaded.
    ///   - model1: The first model.
    ///   - model2: The second model.
    /// - Returns: The detail changes object.
    func detailChangesOutput(_ req: Request, _ model1: Detail, _ model2: Detail) async throws -> DetailChangesResponseObject
    
    /// Sets up the detail changes routes.
    /// - Parameter routes: The routes on which to setup the detail changes routes.
    func setupDetailChangesRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryDetailChangesController {
    @AsyncValidatorBuilder
    func detailChangesValidators() -> [AsyncValidator] {
        KeyedContentValidator<UUID>.required("from")
        KeyedContentValidator<UUID>.required("to")
    }
    
    func beforeDetailChanges(_ req: Request) async throws { }
    
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder
    }
    
    func detailChangesApi(_ req: Request) async throws -> DetailChangesResponseObject {
        try await beforeDetailChanges(req)
        
        try await RequestValidator(detailChangesValidators()).validate(req, .query)
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
