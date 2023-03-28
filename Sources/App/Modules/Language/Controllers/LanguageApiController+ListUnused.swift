//
//  LanguageApiController+ListUnused.swift
//  
//
//  Created by niklhut on 27.09.22.
//

import Vapor
import Fluent
import ISO639
import AppApi

extension AppApi.Language.Detail.ListUnused: Content { }

extension LanguageApiController {
    // MARK: - List unused languages
    
    func listUnusedLanguagesApi(_ req: Request) async throws -> [AppApi.Language.Detail.ListUnused] {
        try await req.onlyFor(.admin)
        
        let existingLanguages = try await LanguageModel.query(on: req.db).all()
        
        let unusedLanguages = ISO639.Language.all.filter { language in !existingLanguages.contains { $0.languageCode == language.alpha1.rawValue } }
        return unusedLanguages.map { language in
            .init(
                languageCode: language.alpha1.rawValue,
                name: language.name,
                officialName: language.official
            )
        }
    }
    
    func setupListUnusedLanguagesRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("unused",  use: listUnusedLanguagesApi)
    }
}
