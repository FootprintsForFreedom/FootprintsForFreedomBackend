//
//  RedirectApiController.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Vapor
import Fluent
import AppApi

extension Redirect.Detail.Detail: Content { }

struct RedirectApiController: ApiController {
    typealias ApiModel = Redirect.Detail
    typealias DatabaseModel = RedirectModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("source", optional: optional)
        KeyedContentValidator<String>.required("destination", optional: optional)
    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("redirects")
    }
    
    // MARK: - Utility
    
    private let charactersToRemoveFromPath = CharacterSet.whitespacesAndNewlines.union(.init(charactersIn: "/"))
    
    private enum StringType: String {
        case source, destination
    }
    
    private func sanitize(_ string: String, ofType type: StringType) throws -> String {
        guard !string.starts(with: "?") else {
            throw Abort(.badRequest, reason: "The \(type.rawValue) only consists of a url query.")
        }
        let output = string.prefix { $0 != "?" }
            .trimmingCharacters(in: charactersToRemoveFromPath)
        guard !output.isEmpty else {
            throw Abort(.badRequest, reason: "Invalid \(type.rawValue)")
        }
        return output
    }
    
    private func countOf(_ value: String, at keyPath: KeyPath<RedirectModel, FieldProperty<RedirectModel, String>>, excludeId idToExclude: UUID? = nil, on db: Database) async throws -> Int {
        let baseQuery = RedirectModel
            .query(on: db)
            .filter(keyPath == value)
        if let idToExclude {
            return try await baseQuery
                .filter(\.$id != idToExclude)
                .count()
        }
        return try await baseQuery.count()
    }
    
    // MARK: - List
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<RedirectModel>) async throws -> QueryBuilder<RedirectModel> {
        try await req.onlyFor(.admin)
        return queryBuilder
    }
    
    func listOutput(_ req: Request, _ models: Fluent.Page<RedirectModel>) async throws -> Fluent.Page<Redirect.Detail.List> {
        return try await models.concurrentMap { try await detailOutput(req, $0) }
    }
    
    // MARK: - Detail
    
    func beforeDetail(_ req: Request, _ queryBuilder: QueryBuilder<RedirectModel>) async throws -> QueryBuilder<RedirectModel> {
        try await req.onlyFor(.admin)
        return queryBuilder
    }
    
    func detailOutput(_ req: Request, _ model: RedirectModel) async throws -> Redirect.Detail.Detail {
        try .init(id: model.requireID(), source: model.source, destination: model.destination)
    }
    
    // MARK: - Create
    
    func beforeCreate(_ req: Request, _ model: RedirectModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    func createInput(_ req: Request, _ model: RedirectModel, _ input: Redirect.Detail.Create) async throws {
        let source = try sanitize(input.source, ofType: .source)
        let destination = try sanitize(input.destination, ofType: .destination)
        guard source != destination else {
            throw Abort(.badRequest, reason: "Source and destination are equal")
        }
        
        let sameSourceCount = try await countOf(source, at: \.$source, excludeId: model.id, on: req.db)
        guard sameSourceCount == 0 else {
            throw Abort(.badRequest, reason: "A redirect with this source already exists.")
        }
        let sourceAsDestinationCount = try await countOf(source, at: \.$destination, excludeId: model.id, on: req.db)
        guard sourceAsDestinationCount == 0 else {
            throw Abort(.badRequest, reason: "Another redirect has this source as destination.")
        }
        let destinationAsSourceCount = try await countOf(destination, at: \.$source, excludeId: model.id, on: req.db)
        guard destinationAsSourceCount == 0 else {
            throw Abort(.badRequest, reason: "Another redirect has this destination as source.")
        }
        
        model.source = source
        model.destination = destination
    }
    
    // MARK: - Update
    
    func beforeUpdate(_ req: Request, _ model: RedirectModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    func updateInput(_ req: Request, _ model: RedirectModel, _ input: Redirect.Detail.Update) async throws {
        try await createInput(req, model, input)
    }
    
    // MARK: - Patch
    
    func beforePatch(_ req: Request, _ model: RedirectModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    
    func patchInput(_ req: Request, _ model: RedirectModel, _ input: Redirect.Detail.Patch) async throws {
        let updateContent = Redirect.Detail.Update(source: input.source ?? model.source, destination: input.destination ?? model.destination)
        return try await createInput(req, model, updateContent)
    }
    
    // MARK: - Delete
    
    func beforeDelete(_ req: Request, _ model: RedirectModel) async throws {
        try await req.onlyFor(.admin)
    }
}
