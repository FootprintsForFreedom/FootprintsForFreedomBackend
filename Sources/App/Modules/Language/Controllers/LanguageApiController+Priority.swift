//
//  LanguageApiController+Priority.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

extension LanguageApiController {
    
    // PUT: api/languages/:languageId/deactivate
    func deactivateLanguage(_ req: Request) async throws -> Language.Language.Detail {
        try await req.onlyFor(.admin)
        
        let language = try await findBy(identifier(req), on: req.db)
        
        guard language.priority != nil else {
            throw Abort(.badRequest)
        }
        
        language.priority = nil
        try await language.update(on: req.db)
        return try .init(
            id: language.requireID(),
            languageCode: language.languageCode,
            name: language.name,
            isRTL: language.isRTL
        )
    }
    
    // PUT: api/languages/:languageId/activate
    func activateLanguage(_ req: Request) async throws -> Language.Language.Detail {
        try await req.onlyFor(.admin)
        
        let language = try await findBy(identifier(req), on: req.db)
        
        let currentHighestPriority = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        language.priority = currentHighestPriority + 1
        try await language.update(on: req.db)
        return try .init(
            id: language.requireID(),
            languageCode: language.languageCode,
            name: language.name,
            isRTL: language.isRTL
        )
    }
    
    // GET: api/languages/deactivated
    func listDeactivatedLanguages(_ req: Request) async throws -> [Language.Language.Detail] {
        try await req.onlyFor(.admin)
        
        let deactivatedLanguages = try await LanguageModel.query(on: req.db)
            .filter(\.$priority == nil)
            .sort(\.$name)
            .all()
        
        return try deactivatedLanguages.map { language in
            return try .init(
                id: language.requireID(),
                languageCode: language.languageCode,
                name: language.name,
                isRTL: language.isRTL
            )
        }
    }
    
    @AsyncValidatorBuilder
    func setLanguagePrioritiesValidators() -> [AsyncValidator] {
        KeyedContentValidator<[UUID]>.required("newLanguagesOrder")
    }
    
    func setLanguagePriorities(_ req: Request) async throws -> [Language.Language.List] {
        try await req.onlyFor(.admin)
        
        try await RequestValidator(setLanguagePrioritiesValidators()).validate(req)
        let input = try req.content.decode(Language.Language.UpdatePriorities.self)
        let newLanguagesOrder = try await input.newLanguagesOrder
            .concurrentMap { languageId -> LanguageModel in
                guard let language = try await LanguageModel.query(on: req.db)
                    .filter(\.$id == languageId)
                    .filter(\.$priority != nil)
                    .first()
                else {
                    throw Abort(.badRequest)
                }
                return language
            }
        
        let activeLanguageCount = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .count()
        
        guard newLanguagesOrder.count == activeLanguageCount else {
            throw Abort(.badRequest)
        }
        
        try await req.db.transaction { transaction in
            try await newLanguagesOrder.concurrentForEach { language in
                language.priority = nil
                try await language.update(on: transaction)
            }
            
            try await newLanguagesOrder.enumerated().concurrentForEach { index, language in
                language.priority = index + 1
                try await language.update(on: transaction)
            }
        }
        
        return try await listApi(req)
    }
    
    func setupPriorityRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.put("priorities", use: setLanguagePriorities)
        baseRoutes.get("deactivated", use: listDeactivatedLanguages)
        
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.put("deactivate", use: deactivateLanguage)
        existingModelRoutes.put("activate", use: deactivateLanguage)
        
    }
}
