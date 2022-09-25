//
//  LanguageApiController+Priority.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

extension LanguageApiController {
    
    // PUT: api/languages/:languageId/deactivate
    func deactivateLanguage(_ req: Request) async throws -> Language.Detail.Detail {
        try await req.onlyFor(.admin)
        
        let language = try await findBy(identifier(req), on: req.db)
        
        guard language.priority != nil else {
            throw Abort(.badRequest)
        }
        
        try await LatestVerifiedTagModel.Elasticsearch.deactivateLanguage(language.requireID(), on: req)
        try await WaypointSummaryModel.Elasticsearch.deactivateLanguage(language.requireID(), on: req)
        
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
    func activateLanguage(_ req: Request) async throws -> Language.Detail.Detail {
        try await req.onlyFor(.admin)
        
        let language = try await findBy(identifier(req), on: req.db)
        
        guard language.priority == nil else {
            throw Abort(.badRequest)
        }
        
        let currentHighestPriority = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        language.priority = currentHighestPriority + 1
        try await language.update(on: req.db)
        
        try await LatestVerifiedTagModel.Elasticsearch.activateLanguage(language.requireID(), on: req)
        try await WaypointSummaryModel.Elasticsearch.activateLanguage(language.requireID(), on: req)
        
        return try .init(
            id: language.requireID(),
            languageCode: language.languageCode,
            name: language.name,
            isRTL: language.isRTL
        )
    }
    
    // GET: api/languages/deactivated
    func listDeactivatedLanguages(_ req: Request) async throws -> [Language.Detail.Detail] {
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
    
    func setLanguagePriorities(_ req: Request) async throws -> [Language.Detail.List] {
        try await req.onlyFor(.admin)
        try await RequestValidator(setLanguagePrioritiesValidators()).validate(req)
        
        let input = try req.content.decode(Language.Detail.UpdatePriorities.self)
        let oldLanguagesOrder = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .ascending) // Lowest value first
            .all()
        
        guard input.newLanguagesOrder.count == oldLanguagesOrder.count else {
            throw Abort(.badRequest, reason: "'newLanguagesOrder' must contain all active languages.")
        }
        
        let newLanguagesOrder = try input.newLanguagesOrder.map { languageId in
            guard let language = try oldLanguagesOrder.first(where: { try $0.requireID() == languageId }) else {
                throw Abort(.badRequest, reason: "'newLanguagesOrder' must contain all active languages.")
            }
            return language
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
        
        let languagesWithChangedPriority = try newLanguagesOrder.enumerated().compactMap { newIndex, newLanguage in
            if try oldLanguagesOrder[newIndex].requireID() != newLanguage.requireID() {
                return try newLanguage.requireID()
            }
            return nil
        }
        try await LatestVerifiedTagModel.Elasticsearch.updateLanguages(languagesWithChangedPriority, on: req)
        try await WaypointSummaryModel.Elasticsearch.updateLanguages(languagesWithChangedPriority, on: req)
        
        return try await listApi(req)
    }
    
    func setupPriorityRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.put("priorities", use: setLanguagePriorities)
        baseRoutes.get("deactivated", use: listDeactivatedLanguages)
        
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.put("deactivate", use: deactivateLanguage)
        existingModelRoutes.put("activate", use: activateLanguage)
    }
}
