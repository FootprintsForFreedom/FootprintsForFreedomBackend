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
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("languages")
    }
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("languageCode", optional: optional)
        KeyedContentValidator<String>.required("name", optional: optional)
        KeyedContentValidator<Bool>.required("isRTL", optional: optional)
    }
    
    func listOutput(_ req: Request, _ models: Page<LanguageModel>) async throws -> Page<Language.Language.List> {
        models.map { model in
                .init(
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
    
    func updateInput(_ req: Request, _ model: LanguageModel, _ input: Language.Language.Update) async throws {
        model.languageCode = input.languageCode
        model.name = input.name
        model.isRTL = input.isRTL
    }
    
    func patchInput(_ req: Request, _ model: LanguageModel, _ input: Language.Language.Patch) async throws {
        model.languageCode = input.languageCode ?? model.languageCode
        model.name = input.name ?? model.name
        model.isRTL = input.isRTL ?? model.isRTL
    }
    
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
