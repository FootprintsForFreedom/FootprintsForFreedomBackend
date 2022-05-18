//
//  Request+PreferredLanguageCode.swift
//  
//
//  Created by niklhut on 18.05.22.
//

import Vapor

extension Request {
    func preferredLanguageCode() throws -> String? {
        try self.query.decode(PreferredLanguageQuery.self).preferredLanguage
    }
    
    func allLanguageCodesByPriority() async throws -> [String] {
        try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode(), on: self.db)
    }
}
