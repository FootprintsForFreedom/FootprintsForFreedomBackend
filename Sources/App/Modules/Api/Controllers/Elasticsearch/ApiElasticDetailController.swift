//
//  ApiElasticDetailController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import AppApi

/// Streamlines detailing a model from elasticsearch.
protocol ApiElasticDetailController: ElasticModelController {
    /// The detail object content.
    associatedtype DetailObject: Content
    
    /// The detail output for a model.
    /// - Parameters:
    ///   - req: The request on which  to detail the model.
    ///   - model: The model to be detailed.
    /// - Returns: The model detail object.
    func detailOutput(_ req: Request, _ model: ElasticModel, _ availableLanguageCodes: [String]) async throws -> DetailObject
    
    /// The detail api action.
    /// - Parameter req: The request on which to detail the model.
    /// - Returns: The model detail object.
    func detailApi(_ req: Request) async throws -> DetailObject
    
    /// The detail by slug api action.
    ///
    /// Instead of finding the repository by its id this function searches the unique slugs of the details to find the requested repository detail.
    ///
    /// - Parameter req: The request on which to detail the repository.
    /// - Returns: The repository detail object.
    func detailBySlugApi(_ req: Request) async throws -> DetailObject
    
    /// Sets up the model detail routes.
    /// - Parameter routes: The routes on which to setup the model detail routes.
    func setupDetailRoutes(_ routes: RoutesBuilder)
}

extension ApiElasticDetailController {
    func detailApi(_ req: Request) async throws -> DetailObject {
        let (model, availableLanguageCodes) = try await findBy(identifier(req), req.preferredLanguageCode(), on: req.elastic)
        return try await detailOutput(req, model, availableLanguageCodes)
    }
    
    func detailBySlugApi(_ req: Request) async throws -> DetailObject {
        let (model, availableLanguageCodes) = try await findBy(slug(req), on: req.elastic)
        return try await detailOutput(req, model, availableLanguageCodes)
    }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get(use: detailApi)
        
        let slugRoutes = baseRoutes.grouped("find").grouped(ApiModel.pathIdComponent)
        slugRoutes.get(use: detailBySlugApi)
    }
}
