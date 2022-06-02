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
        public let verified: Bool?
        public let detailId: UUID?
        
        public static func publicDetail(id: UUID, title: String, keywords: [String], slug: String, languageCode: String) -> Self {
            return .init(
                id: id,
                title: title,
                keywords: keywords,
                slug: slug,
                languageCode: languageCode
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, keywords: [String], slug: String, languageCode: String, verified: Bool, detailId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                keywords: keywords,
                slug: slug,
                languageCode: languageCode,
                verified: verified,
                detailId: detailId
            )
        }
        
        private init(id: UUID, title: String, keywords: [String], slug: String, languageCode: String) {
            self.id = id
            self.title = title
            self.keywords = keywords
            self.slug = slug
            self.languageCode = languageCode
            self.verified = nil
            self.detailId = nil
        }
        
        private init(id: UUID, title: String, keywords: [String], slug: String, languageCode: String, verified: Bool, detailId: UUID) {
            self.id = id
            self.title = title
            self.keywords = keywords
            self.slug = slug
            self.languageCode = languageCode
            self.verified = verified
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
