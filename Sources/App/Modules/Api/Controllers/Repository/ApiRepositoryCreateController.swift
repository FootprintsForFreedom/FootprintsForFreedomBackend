//
//  ApiRepositoryCreateController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol ApiRepositoryCreateController: RepositoryCreateController {
    associatedtype CreateObject: Decodable

    func createValidators() -> [AsyncValidator]
    func createInput(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel, _ input: CreateObject) async throws
    func createApi(_ req: Request) async throws -> Response
    func createResponse(_ req: Request, _ repository: DatabaseModel, _ object: ObjectModel) async throws -> Response
    func setupCreateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryCreateController {
    func createValidators() -> [AsyncValidator] {
        []
    }
    
    func createApi(_ req: Request) async throws -> Response {
        try await RequestValidator(createValidators()).validate(req)
        let input = try req.content.decode(CreateObject.self)
        let repository = DatabaseModel()
        try await createRepository(req, repository)
        let object = ObjectModel()
        try await createInput(req, repository, object, input)
        try await createObject(req, object)
        return try await createResponse(req, repository, object)
    }
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.post(use: createApi)
    }
}
