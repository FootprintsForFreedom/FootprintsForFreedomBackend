//
//  ApiRepositoryCreateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryCreateController: RepositoryController, CreateController {
    associatedtype CreateObject: Decodable
    
    func createValidators() -> [AsyncValidator]
    func createRepositoryInput(_ req: Request, _ repository: DatabaseModel, _ input: CreateObject) async throws
    func getCreateInput(_ req: Request) async throws -> CreateObject
    func createInput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail, _ input: CreateObject) async throws
    func createApi(_ req: Request) async throws -> Response
    func createResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response
    func setupCreateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryCreateController {
    
    func createValidators() -> [AsyncValidator] {
        []
    }
    
    func getCreateInput(_ req: Request) async throws -> CreateObject {
        try await RequestValidator(createValidators()).validate(req)
        return try req.content.decode(CreateObject.self)
    }
    
    func createRepositoryInput(_ req: Request, _ repository: DatabaseModel, _ input: CreateObject) async throws { }
    
    func createApi(_ req: Request) async throws -> Response {
        let input = try await getCreateInput(req)
        let repository = DatabaseModel()
        try await createRepositoryInput(req, repository, input)
        try await create(req, repository)
        let detail = Detail()
        try await createInput(req, repository, detail, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository._$details.create(detail, on: req.db)
        return try await createResponse(req, repository, detail)
    }
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.post(use: createApi)
    }
}
