//
//  LanguageApiController.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor
import Fluent

extension Language.Language.List: Content { }
extension Language.Language.Detail: Content { }

struct LanguageApiController: ApiController {
    typealias ApiModel = Language.Language
    typealias DatabaseModel = LanguageModel
    
    func onlyForAdmin(_ req: Request) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a admin or higher
        guard user.role >= .admin else {
            throw Abort(.forbidden)
        }
    }
    
    func requireUniqueLanguageCode(_ req: Request, _ model: LanguageModel) async throws {
        guard try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == model.languageCode)
                .count() == 0
        else {
            throw Abort(.badRequest)
        }
    }
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("languages")
    }
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("languageCode", optional: optional)
        KeyedContentValidator<String>.required("name", optional: optional)
        KeyedContentValidator<Bool>.required("isRTL", optional: optional)
    }
    
    func list(_ req: Request) async throws -> Page<LanguageModel> {
        let queryBuilder = LanguageModel.query(on: req.db)
        let numberOfLanguages = try await queryBuilder.count()
        let list = try await beforeList(req, queryBuilder).paginate(PageRequest(page: 1, per: numberOfLanguages))
        return try await afterList(req, list)
    }
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<LanguageModel>) async throws -> QueryBuilder<LanguageModel> {
        queryBuilder.sort(\.$priority, .ascending) // Lowest value first
    }
    
    func listOutput(_ req: Request, _ models: Page<LanguageModel>) async throws -> Page<Language.Language.List> {
        models.map { model in
            return .init(
                id: model.id!,
                languageCode: model.languageCode,
                name: model.name,
                isRTL: model.isRTL
            )
        }
    }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(":languageCode")
        existingModelRoutes.get(use: detailApi)
    }
    
    func languageCode(_ req: Request) throws -> String {
        guard let languageCode = req.parameters.get("languageCode", as: String.self) else {
            throw Abort(.badRequest)
        }
        return languageCode
    }
    
    func detail(_ req: Request) async throws -> LanguageModel {
        let queryBuilder = LanguageModel.query(on: req.db)
        let model = try await beforeDetail(req, queryBuilder).filter(\.$languageCode == languageCode(req)).first()
        guard let model = model else {
            throw Abort(.notFound)
        }
        return try await afterDetail(req, model)
    }
    
    func detailOutput(_ req: Request, _ model: LanguageModel) async throws -> Language.Language.Detail {
        return .init(
            id: model.id!,
            languageCode: model.languageCode,
            name: model.name,
            isRTL: model.isRTL
        )
    }
    
    func beforeCreate(_ req: Request, _ model: LanguageModel) async throws {
        try await onlyForAdmin(req)
        try await requireUniqueLanguageCode(req, model)
    }
    
    func createInput(_ req: Request, _ model: LanguageModel, _ input: Language.Language.Create) async throws {
        let currentHighestPriority = try await LanguageModel
            .query(on: req.db)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        model.languageCode = input.languageCode
        model.name = input.name
        model.isRTL = input.isRTL
        model.priority = currentHighestPriority + 1
    }
    
    func beforeUpdate(_ req: Request, _ model: LanguageModel) async throws {
        try await onlyForAdmin(req)
        try await requireUniqueLanguageCode(req, model)
    }
    
    func updateInput(_ req: Request, _ model: LanguageModel, _ input: Language.Language.Update) async throws {
        model.languageCode = input.languageCode
        model.name = input.name
        model.isRTL = input.isRTL
    }
    
    func beforePatch(_ req: Request, _ model: LanguageModel) async throws {
        try await onlyForAdmin(req)
        if try await LanguageModel.find(model.requireID(), on: req.db)?.languageCode != model.languageCode {
            try await requireUniqueLanguageCode(req, model)
        }
    }
    
    func patchInput(_ req: Request, _ model: LanguageModel, _ input: Language.Language.Patch) async throws {
        if input.languageCode == nil && input.name == nil && input.isRTL == nil {
            throw Abort(.badRequest)
        }
        
        model.languageCode = input.languageCode ?? model.languageCode
        model.name = input.name ?? model.name
        model.isRTL = input.isRTL ?? model.isRTL
    }
    
    // TODO: maybe archive or deactivate language --> just remove the priority; then it does not get indexed anymore
    
    // TODO: reorder language priorities
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
    }
}
