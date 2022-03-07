//
//  ApiRepositoryUpdateController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol ApiRepositoryUpdateController: RepositoryUpdateController {
    associatedtype UpdateObject: Decodable
    
    func updateValidators() -> [AsyncValidator]
    func updateInput(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel, _ input: UpdateObject) async throws
    func updateApi(_ req: Request) async throws -> Response
    func updateResponse(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws -> Response
    func setupUpdateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryUpdateController {
    func updateValidators() -> [AsyncValidator] {
        []
    }
    
    func updateApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updateValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(UpdateObject.self)
        let object = ObjectModel()
        try await updateInput(req, repository, object, input)
        try await update(req, repository, object)
        return try await updateResponse(req, repository, object)
    }
    
    func setupUpdateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.put(use: updateApi)
    }
}
