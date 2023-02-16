//
//  LanguageModel.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor
import Fluent
import ISO639

final class LanguageModel: DatabaseModelInterface {
    typealias Module = LanguageModule
    
    static let schema = "languages"
    
    struct FieldKeys {
        struct v1 {
            static var languageCode: FieldKey { "language_code" }
            static var name: FieldKey { "name" }
            static var officialName: FieldKey { "official_name" }
            static var isRTL: FieldKey { "is_rtl" }
            static var priority: FieldKey { "priority" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.languageCode) private(set) var languageCode: String
    @Field(key: FieldKeys.v1.name) private(set) var name: String
    @Field(key: FieldKeys.v1.officialName) private(set) var officialName: String
    @Field(key: FieldKeys.v1.isRTL) private(set) var isRTL: Bool
    @OptionalField(key: FieldKeys.v1.priority) var priority: Int?
    
    init() { }
    
    init(languageCode: String, priority: Int?) throws {
        try self.from(languageCode)
        self.priority = priority
    }
}

extension LanguageModel {
    func from(_ languageCode: String) throws {
        guard let language = Language.from(with: languageCode) else { throw Abort(.badRequest, reason: "Invalid ISO639-1 language code.") }
        let rtlLanguageCodes = ["ar", "arc", "dv", "fa", "ha", "he", "khw", "ks", "ku", "ps", "ur", "yi"]
        self.languageCode = language.alpha1.rawValue
        self.name = language.name
        self.officialName = language.official
        self.isRTL = rtlLanguageCodes.contains(language.alpha1.rawValue) ? true : false
    }
    
    static func languageCodesByPriority(preferredLanguageCode: String? = nil, on db: Database) async throws -> [String] {
        return try await self
            .query(on: db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .ascending) // Lowest value first
            .all()
            .map { $0.languageCode }
            .inserting(preferredLanguageCode, at: 0)
            .uniqued()
    }
    
    static func activeLanguages(on db: Database) async throws -> [LanguageModel] {
        try await self
            .query(on: db)
            .filter(\.$priority != nil)
            .all()
    }
}
