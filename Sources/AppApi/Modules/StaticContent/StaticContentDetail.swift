//
//  StaticContentDetail.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Foundation

public extension StaticContent {
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.StaticContent
    }
}

public extension StaticContent.Detail {
    struct List: Codable {
        public let id: UUID
        public let slug: String
        
        public init(id: UUID, slug: String) {
            self.id = id
            self.slug = slug
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let title: String
        public let text: String
        public let languageCode: String
        public let availableLanguageCodes: [String]
        public let moderationTitle: String?
        public let requiredSnippets: [StaticContent.Snippet]?
        public let detailId: UUID?
        
        public static func publicDetail(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String]) -> Self {
            return .init(
                id: id,
                title: title,
                text: text,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes
            )
        }
        
        public static func administratorDetail(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String], moderationTitle: String?, requiredSnippets: [StaticContent.Snippet]?, detailId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                text: text,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                moderationTitle: moderationTitle,
                requiredSnippets: requiredSnippets,
                detailId: detailId
            )
        }
        
        private init(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String]) {
            self.id = id
            self.title = title
            self.text = text
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.moderationTitle = nil
            self.requiredSnippets = nil
            self.detailId = nil
        }
        
        private init(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String], moderationTitle: String?, requiredSnippets: [StaticContent.Snippet]?, detailId: UUID) {
            self.id = id
            self.title = title
            self.text = text
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.moderationTitle = moderationTitle
            self.requiredSnippets = requiredSnippets
            self.detailId = detailId
        }
    }
    
    struct Create: Codable {
        public let repositoryTitle: String
        public let moderationTitle: String
        public let title: String
        public let text: String
        public let requiredSnippets: [StaticContent.Snippet]?
        public let languageCode: String
        
        public init(repositoryTitle: String, moderationTitle: String, title: String, text: String, requiredSnippets: [StaticContent.Snippet]?, languageCode: String) {
            self.repositoryTitle = repositoryTitle
            self.moderationTitle = moderationTitle
            self.title = title
            self.text = text
            self.requiredSnippets = requiredSnippets
            self.languageCode = languageCode
        }
    }
    
    struct Update: Codable {
        public let moderationTitle: String
        public let title: String
        public let text: String
        public let languageCode: String
        
        public init(moderationTitle: String, title: String, text: String, languageCode: String) {
            self.moderationTitle = moderationTitle
            self.title = title
            self.text = text
            self.languageCode = languageCode
        }
    }
    
    struct Patch: Codable {
        public let moderationTitle: String?
        public let title: String?
        public let text: String?
        public let idForStaticContentDetailToPatch: UUID
        
        public init(moderationTitle: String?, title: String?, text: String?, idForStaticContentDetailToPatch: UUID) {
            self.moderationTitle = moderationTitle
            self.title = title
            self.text = text
            self.idForStaticContentDetailToPatch = idForStaticContentDetailToPatch
        }
    }
}
