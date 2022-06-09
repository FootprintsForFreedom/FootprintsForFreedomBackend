//
//  TagDetail.swift
//  
//
//  Created by niklhut on 23.05.22.
//

import Foundation

public extension Tag {
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Tag
    }
}

public extension Tag.Detail {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let slug: String
        
        public init(id: UUID, title: String, slug: String) {
            self.id = id
            self.title = title
            self.slug = slug
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let title: String
        public let keywords: [String]
        public let slug: String
        public let languageCode: String
        public let availableLanguageCodes: [String]
        public let status: Status?
        public let detailId: UUID?
        
        public static func publicDetail(id: UUID, title: String, keywords: [String], slug: String, languageCode: String, availableLanguageCodes: [String]) -> Self {
            return .init(
                id: id,
                title: title,
                keywords: keywords,
                slug: slug,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, keywords: [String], slug: String, languageCode: String, availableLanguageCodes: [String], status: Status, detailId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                keywords: keywords,
                slug: slug,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                status: status,
                detailId: detailId
            )
        }
        
        private init(id: UUID, title: String, keywords: [String], slug: String, languageCode: String, availableLanguageCodes: [String]) {
            self.id = id
            self.title = title
            self.keywords = keywords
            self.slug = slug
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.status = nil
            self.detailId = nil
        }
        
        private init(id: UUID, title: String, keywords: [String], slug: String, languageCode: String, availableLanguageCodes: [String], status: Status, detailId: UUID) {
            self.id = id
            self.title = title
            self.keywords = keywords
            self.slug = slug
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.status = status
            self.detailId = detailId
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let keywords: [String]
        public let languageCode: String
        
        public init(title: String, keywords: [String], languageCode: String) {
            self.title = title
            self.keywords = keywords
            self.languageCode = languageCode
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let keywords: [String]
        public let languageCode: String
        
        public init(title: String, keywords: [String], languageCode: String) {
            self.title = title
            self.keywords = keywords
            self.languageCode = languageCode
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let keywords: [String]?
        public let idForTagDetailToPatch: UUID
        
        public init(title: String?, keywords: [String]?, idForTagDetailToPatch: UUID) {
            self.title = title
            self.keywords = keywords
            self.idForTagDetailToPatch = idForTagDetailToPatch
        }
    }
}
