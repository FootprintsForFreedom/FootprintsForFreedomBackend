//
//  LanguageApiController+Priority.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent

extension LanguageApiController {
    
    // TODO: activate and deactivate language
//    func deactivateLanguage(_ req: Request) async throws -> Language.Language.Detail {
//
//    }
//
//    func activateLanguage(_ req: Request) async throws -> Language.Language.Detail {
//
//    }
//
//    func getDeactivatedLanguages(_ req: Request) async throws -> [Language.Language.Detail] {
//
//    }
    
    @AsyncValidatorBuilder
    func setLanguageValidators() -> [AsyncValidator] {
        KeyedContentValidator<[UUID]>.required("newLanguagesOrder")
    }
    
    func setLanguagePriorities(_ req: Request) async throws -> [Language.Language.Detail] {
        let input = try req.content.decode(Language.Language.UpdatePriorities.self)
        let newLanguagesOrder = try await input.newLanguagesOrder
            .concurrentMap { languageId -> LanguageModel in
                guard let language = try await LanguageModel.find(languageId, on: req.db) else {
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
            try await newLanguagesOrder.enumerated().asyncForEach { index, language in
                language.priority = index + 1
                try await language.update(on: transaction)
            }
        }
        
        return try await LanguageModel
            .query(on: req.db)
            .sort(\.$priority, .ascending) // Lowest value first
            .all()
            .map { language in
                return .init(
                    id: language.id!,
                    languageCode: language.languageCode,
                    name: language.name,
                    isRTL: language.isRTL
                )
            }
    }
}
