//
//  ApiRepositoryCreateController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol ApiRepositoryCreateController: RepositoryCreateController {
    associatedtype CreateObject: Decodable
    
    func createValidators() -> [AsyncValidator]
    func createRepositoryInput(_ req: Request, _ repository: Repository, _ input: CreateObject) async throws
    func getCreateInput(_ req: Request) throws -> CreateObject
    func createInput(_ req: Request, _ repository: Repository, _ detail: Detail, _ input: CreateObject) async throws
    func createApi(_ req: Request) async throws -> Response
    func createResponse(_ req: Request, _ repository: Repository, _ detail: Detail) async throws -> Response
    func setupCreateRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryCreateController {
    
    func createValidators() -> [AsyncValidator] {
        []
    }
    
    func getCreateInput(_ req: Request) throws -> CreateObject {
        try req.content.decode(CreateObject.self)
    }
    
    func createRepositoryInput(_ req: Request, _ repository: Repository, _ input: CreateObject) async throws { }
    
    func createApi(_ req: Request) async throws -> Response {
        try await RequestValidator(createValidators()).validate(req)
        let input = try getCreateInput(req)
        let repository = Repository()
        try await createRepositoryInput(req, repository, input)
        try await create(req, repository)
        let detail = Detail()
        try await createInput(req, repository, detail, input)
        try await repository._$details.create(detail, on: req.db)
        return try await createResponse(req, repository, detail)
    }
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.post(use: createApi)
    }
}
