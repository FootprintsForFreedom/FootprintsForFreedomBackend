//
//  ApiRepositoryUpdateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryUpdateController: RepositoryUpdateController {
    associatedtype UpdateObject: Decodable
    
    func updateValidators() -> [AsyncValidator]
    func getUpdateInput(_ req: Request) throws -> UpdateObject
    func updateInput(_ req: Request, _ repository: Repository, _ detail: Detail, _ input: UpdateObject) async throws
    func updateApi(_ req: Request) async throws -> Response
    func updateResponse(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> Response
    func setupUpdateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryUpdateController {
    
    func updateValidators() -> [AsyncValidator] {
        []
    }
    
    func getUpdateInput(_ req: Request) throws -> UpdateObject {
        try req.content.decode(UpdateObject.self)
    }
    
    func updateApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updateValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try getUpdateInput(req)
        try await beforeUpdate(req, repository)
        let detail = Detail()
        try await updateInput(req, repository, detail, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository.update(on: req.db)
        try await repository._$details.create(detail, on: req.db)
        try await afterUpdate(req, repository)
        return try await updateResponse(req, repository, detail)
    }
    
    func setupUpdateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.put(use: updateApi)
    }
}
