//
//  LanguageModel.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor
import Fluent

final class LanguageModel: DatabaseModelInterface {
    typealias Module = LanguageModule
    
    static let schema = "languages"
    
    struct FieldKeys {
        struct v1 {
            static var languageCode: FieldKey { "language_code" }
            static var name: FieldKey { "name" }
            static var isRTL: FieldKey { "is_rtl" }
            static var priority: FieldKey { "priority" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.languageCode) var languageCode: String
    @Field(key: FieldKeys.v1.name) var name: String
    @Field(key: FieldKeys.v1.isRTL) var isRTL: Bool
    @Field(key: FieldKeys.v1.priority) var priority: Int
    
    init() { }
    
    init(
        id: UUID? = nil,
        languageCode: String,
        name: String,
        isRTL: Bool,
        priority: Int
    ) {
        self.id = id
        self.languageCode = languageCode
        self.name = name
        self.isRTL = isRTL
        self.priority = priority
    }
}

extension LanguageModel {
    // TODO: test this function
    static func languageCodesByPriority(preferredLanguageCode: String? = nil, on db: Database) async throws -> [String] {
        return try await self
            .query(on: db)
            .sort(\.$priority, .ascending)
            .all()
            .map { $0.languageCode }
            .inserting(preferredLanguageCode, at: 0)
            .uniqued()
    }
}
