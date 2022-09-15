//
//  TagApiController.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

extension Tag.Detail.List: Content { }
extension Tag.Detail.Detail: Content { }

struct TagApiController: ApiRepositoryController {
    typealias ApiModel = Tag.Detail
    typealias DatabaseModel = TagRepositoryModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<[String]>.required("keywords")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<[String]>.required("keywords")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: true)
        KeyedContentValidator<[String]>.required("keywords", optional: true)
        KeyedContentValidator<UUID>.required("idForTagDetailToPatch")
    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("tags")
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
    
    // MARK: - List
    
    func listOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Tag.Detail.List {
        return try .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug
        )
    }
    
    // MARK: - Detail
    
    func detailOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Tag.Detail.Detail {
        try await detail.$language.load(on: req.db)
        
        return try await .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            keywords: detail.keywords,
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(req.db),
            detailId: detail.requireID()
        )
    }
    
    // MARK: - Create
    
    func beforeCreate(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func createInput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail, _ input: Tag.Detail.Create) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == input.languageCode)
                .first()?
                .requireID()
        else {
            throw Abort(.badRequest, reason: "The language code is invalid")
        }
        
        let keywords = input.keywords.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        guard !keywords.isEmpty else {
            throw Abort(.badRequest, reason: "The keywords are invalid")
        }
        
        detail.title = input.title
        detail.keywords = keywords
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    // MARK: - Update
    
    func beforeUpdate(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func updateInput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail, _ input: Tag.Detail.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == input.languageCode)
                .first()?
                .requireID()
        else {
            throw Abort(.badRequest, reason: "The language code is invalid")
        }
        
        let keywords = input.keywords.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        guard !keywords.isEmpty else {
            throw Abort(.badRequest, reason: "The keywords are invalid")
        }
        
        detail.title = input.title
        detail.keywords = keywords
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    // MARK: - Patch
    
    func beforePatch(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func patchInput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail, _ input: Tag.Detail.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let tagToPatch = try await TagDetailModel.find(input.idForTagDetailToPatch, on: req.db) else {
            throw Abort(.badRequest, reason: "No tag with the given id could be found")
        }
        
        guard input.title != nil || input.keywords != nil else {
            throw Abort(.badRequest)
        }
        
        detail.title = input.title ?? tagToPatch.title
        
        if let keywords = input.keywords {
            let keywords = keywords.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
            guard !keywords.isEmpty else {
                throw Abort(.badRequest, reason: "The keywords are invalid")
            }
            detail.keywords = keywords
        } else {
            detail.keywords = tagToPatch.keywords
        }
        
        detail.$language.id = tagToPatch.$language.id
        detail.$user.id = user.id
    }
    
    // MARK: - Delete
    
    func beforeDelete(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func afterDelete(_ req: Request, _ model: TagRepositoryModel) async throws {
        let languageCodes = try await LanguageModel.query(on: req.db).all()
        let elementsToDelete = try languageCodes.map { try ESBulkOperation(operationType: .delete, index: "tags", id: "\(model.requireID())_\($0.languageCode)", document: LatestVerifiedTagModel.Elasticsearch.Delete()) }
        let deleteResponse = try req.elastic.bulk(elementsToDelete)
        print(deleteResponse)
    }
}
