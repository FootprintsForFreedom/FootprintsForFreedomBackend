//
//  LanguageApiController.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor
import Fluent

extension Language.Detail.Detail: Content { }

struct LanguageApiController: UnpagedApiController {
    typealias ApiModel = Language.Detail
    typealias DatabaseModel = LanguageModel
    
    func requireUniqueLanguageCode(_ req: Request, _ model: LanguageModel) async throws {
        guard try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == model.languageCode)
                .count() == 0
        else {
            throw Abort(.badRequest, reason: "Unique language code is required. The language code \"\(model.languageCode)\" already exists.")
        }
    }
    
    func requireUniqueName(_ req: Request, _ model: LanguageModel) async throws {
        guard try await LanguageModel
                .query(on: req.db)
                .filter(\.$name == model.name)
                .count() == 0
        else {
            throw Abort(.badRequest, reason: "Unique language name is required. The language name \"\(model.name)\" already exists.")
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
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<LanguageModel>) async throws -> QueryBuilder<LanguageModel> {
        queryBuilder
            .filter(\.$priority != nil)
            .sort(\.$priority, .ascending) // Lowest value first
    }
    
    func listOutput(_ req: Request, _ models: [LanguageModel]) async throws -> [Language.Detail.List] {
        models.map { model in
            return .init(
                id: model.id!,
                languageCode: model.languageCode,
                name: model.name,
                isRTL: model.isRTL
            )
        }
    }
    
    var languageCodePathIdKey: String { "languageCode" }
    var languageCodePathIdComponent: PathComponent { .init(stringLiteral: ":" + languageCodePathIdKey) }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(languageCodePathIdComponent)
        existingModelRoutes.get(use: detailApi)
    }
    
    func languageCode(_ req: Request) throws -> String {
        guard let languageCode = req.parameters.get(languageCodePathIdKey, as: String.self) else {
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
    
    func afterDetail(_ req: Request, _ model: LanguageModel) async throws -> LanguageModel {
        if model.priority == nil {
            try await req.onlyFor(.admin)
        }
        return model
    }
    
    func detailOutput(_ req: Request, _ model: LanguageModel) async throws -> Language.Detail.Detail {
        return .init(
            id: model.id!,
            languageCode: model.languageCode,
            name: model.name,
            isRTL: model.isRTL
        )
    }
    
    func beforeCreate(_ req: Request, _ model: LanguageModel) async throws {
        try await req.onlyFor(.admin)
        try await requireUniqueLanguageCode(req, model)
        try await requireUniqueName(req, model)
    }
    
    func createInput(_ req: Request, _ model: LanguageModel, _ input: Language.Detail.Create) async throws {
        let currentHighestPriority = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        model.languageCode = input.languageCode
        model.name = input.name
        model.isRTL = input.isRTL
        model.priority = currentHighestPriority + 1
    }
    
    func beforeUpdate(_ req: Request, _ model: LanguageModel) async throws {
        try await req.onlyFor(.admin)
        guard let savedLanguage = try await LanguageModel.find(model.requireID(), on: req.db) else {
            throw Abort(.badRequest)
        }
        if savedLanguage.languageCode != model.languageCode {
            try await requireUniqueLanguageCode(req, model)
        }
        if savedLanguage.name != model.name {
            try await requireUniqueName(req, model)
        }
    }
    
    func updateInput(_ req: Request, _ model: LanguageModel, _ input: Language.Detail.Update) async throws {
        model.languageCode = input.languageCode
        model.name = input.name
        model.isRTL = input.isRTL
    }
    
    func beforePatch(_ req: Request, _ model: LanguageModel) async throws {
        try await req.onlyFor(.admin)
        guard let savedLanguage = try await LanguageModel.find(model.requireID(), on: req.db) else {
            throw Abort(.badRequest)
        }
        if savedLanguage.languageCode != model.languageCode {
            try await requireUniqueLanguageCode(req, model)
        }
        if savedLanguage.name != model.name {
            try await requireUniqueName(req, model)
        }
    }
    
    func patchInput(_ req: Request, _ model: LanguageModel, _ input: Language.Detail.Patch) async throws {
        if input.languageCode == nil && input.name == nil && input.isRTL == nil {
            throw Abort(.badRequest)
        }
        
        model.languageCode = input.languageCode ?? model.languageCode
        model.name = input.name ?? model.name
        model.isRTL = input.isRTL ?? model.isRTL
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
    }
}
