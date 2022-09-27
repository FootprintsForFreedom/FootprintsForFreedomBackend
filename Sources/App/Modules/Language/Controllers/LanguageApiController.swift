//
//  LanguageApiController.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor
import Fluent

extension Language.Detail.Detail: Content { }

struct LanguageApiController: ApiListController, ApiDetailController, ApiCreateController {
    typealias ApiModel = Language.Detail
    typealias DatabaseModel = LanguageModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("languageCode")
    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("languages")
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupListUnusedLanguagesRoutes(protectedRoutes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
    }
    
    // MARK: - List
    
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
                officialName: model.officialName,
                isRTL: model.isRTL
            )
        }
    }
    
    // MARK: - Detail
    
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
            officialName: model.officialName,
            isRTL: model.isRTL
        )
    }
    
    // MARK: - Create
    
    func beforeCreate(_ req: Request, _ model: LanguageModel) async throws {
        try await req.onlyFor(.admin)
    }
    
    func createInput(_ req: Request, _ model: LanguageModel, _ input: Language.Detail.Create) async throws {
        let existingLanguages = try await LanguageModel.query(on: req.db).all()
        
        guard !existingLanguages
            .map(\.languageCode)
            .contains(input.languageCode)
        else {
            throw Abort(.badRequest, reason: "The language with this language code already exists.")
        }
        
        let currentHighestPriority = existingLanguages
            .compactMap(\.priority)
            .max() ?? 0
        
        try model.from(input.languageCode)
        model.priority = currentHighestPriority + 1
    }
    
    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(status: .created, for: req)
    }
}
