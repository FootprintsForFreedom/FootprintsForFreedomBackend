//
//  Request+PreferredLanguageCode.swift
//  
//
//  Created by niklhut on 18.05.22.
//

import Vapor
import AppApi

extension Request {
    func preferredLanguageCode() throws -> String? {
        try self.query.decode(Language.Request.PreferredLanguage.self).preferredLanguage
    }
    
    func allLanguageCodesByPriority() async throws -> [String] {
        try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode(), on: self.db)
    }
}
