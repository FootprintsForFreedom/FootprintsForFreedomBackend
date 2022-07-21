//
//  StaticContentApiController.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor
import Fluent

extension StaticContent.Detail.List: Content { }
extension StaticContent.Detail.Detail: Content { }

struct StaticContentApiController: ApiRepositoryController {
    typealias ApiModel = StaticContent.Detail
    typealias DatabaseModel = StaticContentRepositoryModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("repositoryTitle")
        KeyedContentValidator<String>.required("moderationTitle")
        KeyedContentValidator<[StaticContent.Snippet]>.required("requiredSnippets", optional: true)
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("moderationTitle")
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("moderationTitle", optional: true)
        KeyedContentValidator<String>.required("title", optional: true)
        KeyedContentValidator<String>.required("text", optional: true)
        KeyedContentValidator<UUID>.required("idForStaticContentDetailToPatch")
    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("staticContent")
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(protectedRoutes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
    
    // MARK: - List
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<StaticContentRepositoryModel>) async throws -> QueryBuilder<StaticContentRepositoryModel> {
        try await req.onlyFor(.admin)
        return queryBuilder
    }
    
    func listOutput(_ req: Request, _ repositories: Page<DatabaseModel>) async throws -> Page<StaticContent.Detail.List> {
        return try await repositories
            .concurrentCompactMap { repository in
                // load the repository with all fields since the passed parameter can only contain the id field
                guard let repository = try await StaticContentRepositoryModel.find(repository.requireID(), on: req.db) else {
                    throw Abort(.notFound)
                }
                return try .init(
                    id: repository.requireID(),
                    slug: repository.slug
                )
            }
    }
    
    // this function is not implemented since the one calling it was overriden above
    func listOutput(_ req: Request, _ repository: StaticContentRepositoryModel, _ detail: Detail) async throws -> StaticContent.Detail.List {
        fatalError()
    }
    
    // MARK: - Detail
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get(use: detailApi)
    }
    
    func detailApi(_ req: Request) async throws -> StaticContent.Detail.Detail {
        let repository: DatabaseModel? = try await {
            guard let parameter = req.parameters.get(ApiModel.pathIdKey) else {
                throw Abort(.badRequest)
            }
            
            if let id = UUID(uuidString: parameter) {
                return try await DatabaseModel.find(id, on: req.db)
            } else if parameter == parameter.slugify() {
                return try await DatabaseModel
                    .query(on: req.db)
                    .filter(\.$slug == parameter)
                    .first()
            } else {
                return nil
            }
        }()
        
        guard let repository, let detail = try await repository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await detailOutput(req, repository, detail)
    }
    
    func detailOutput(_ req: Request, _ repository: StaticContentRepositoryModel, _ detail: Detail) async throws -> StaticContent.Detail.Detail {
        try await detail.$language.load(on: req.db)
        
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db), user.role >= .admin {
            return try await .administratorDetail(
                id: repository.requireID(),
                title: detail.title,
                text: detail.text,
                languageCode: detail.language.languageCode,
                availableLanguageCodes: repository.availableLanguageCodes(req.db),
                detailId: detail.requireID(),
                moderationTitle: detail.moderationTitle,
                requiredSnippets: repository.requiredSnippets
            )
        } else {
            return try await .publicDetail(
                id: repository.requireID(),
                title: detail.title,
                text: detail.text,
                languageCode: detail.language.languageCode,
                availableLanguageCodes: repository.availableLanguageCodes(req.db),
                detailId: detail.requireID()
            )
        }
    }
    
    // MARK: - Create
    
    func beforeCreate(_ req: Request, _ repository: StaticContentRepositoryModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    func getCreateInput(_ req: Request) async throws -> CreateObject {
        try await RequestValidator(createValidators()).validate(req)
        do {
            return try req.content.decode(CreateObject.self)
        } catch {
            throw Abort(.badRequest)
        }
    }
    
    func createRepositoryInput(_ req: Request, _ repository: StaticContentRepositoryModel, _ input: StaticContent.Detail.Create) async throws {
        let slug = input.repositoryTitle.slugify()
        
        let numberOfDetailsWithSlug = try await DatabaseModel
            .query(on: req.db)
            .filter(\.$slug == slug)
            .count()
        
        guard numberOfDetailsWithSlug == 0 else {
            throw Abort(.badRequest)
        }
        
        repository.slug = slug
        repository.requiredSnippets = input.requiredSnippets ?? []
    }
    
    func createInput(_ req: Request, _ repository: StaticContentRepositoryModel, _ detail: Detail, _ input: StaticContent.Detail.Create) async throws {
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
        
        for requiredSnippet in repository.requiredSnippets {
            guard input.text.contains(requiredSnippet.rawValue) else {
                throw Abort(.badRequest, reason: "Text must contain \(requiredSnippet.rawValue)")
            }
        }
        
        detail.moderationTitle = input.moderationTitle
        detail.title = input.title
        detail.text = input.text
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    // MARK: - Update
    
    func beforeUpdate(_ req: Request, _ repository: StaticContentRepositoryModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    func updateInput(_ req: Request, _ repository: StaticContentRepositoryModel, _ detail: Detail, _ input: StaticContent.Detail.Update) async throws {
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
        
        for requiredSnippet in repository.requiredSnippets {
            guard input.text.contains(requiredSnippet.rawValue) else {
                throw Abort(.badRequest, reason: "Text must contain \(requiredSnippet.rawValue)")
            }
        }
        
        detail.moderationTitle = input.moderationTitle
        detail.title = input.title
        detail.text = input.text
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    // MARK: - Patch
    
    func beforePatch(_ req: Request, _ repository: StaticContentRepositoryModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    func patchInput(_ req: Request, _ repository: StaticContentRepositoryModel, _ detail: Detail, _ input: StaticContent.Detail.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let staticContentToPatch = try await StaticContentDetailModel.find(input.idForStaticContentDetailToPatch, on: req.db) else {
            throw Abort(.badRequest, reason: "No static content with the given id could be found")
        }
        
        guard input.title != nil || input.text != nil || input.moderationTitle != nil else {
            throw Abort(.badRequest)
        }
        
        if let newText = input.text {
            for requiredSnippet in repository.requiredSnippets {
                guard newText.contains(requiredSnippet.rawValue) else {
                    throw Abort(.badRequest, reason: "Text must contain \(requiredSnippet.rawValue)")
                }
            }
        }
        
        detail.moderationTitle = input.moderationTitle ?? staticContentToPatch.moderationTitle
        detail.title = input.title ?? staticContentToPatch.title
        detail.text = input.text ?? staticContentToPatch.text
        detail.$language.id = staticContentToPatch.$language.id
        detail.$user.id = user.id
    }
    
    // MARK: - Delete
    
    func beforeDelete(_ req: Request, _ repository: StaticContentRepositoryModel) async throws {
        try await req.onlyFor(.admin)
    }
}
