//
//  TagDetail.swift
//  
//
//  Created by niklhut on 23.05.22.
//

import Foundation

public extension Tag {
    /// Contains the tag detail data transfer objects.
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Tag
    }
}

public extension Tag.Detail {
    /// Used to list tag objects.
    struct List: Codable {
        /// Id uniquely identifying the tag repository.
        public let id: UUID
        /// The tag title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        
        /// Creates a tag list object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the tag repository.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        public init(id: UUID, title: String, slug: String) {
            self.id = id
            self.title = title
            self.slug = slug
        }
    }
    
    /// Used to detail tag objects.
    struct Detail: Codable {
        /// Id uniquely identifying the tag repository.
        public let id: UUID
        /// The tag title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        /// The keywords connected to this tag.
        public let keywords: [String]
        /// The language code for the tag title and keywords.
        public let languageCode: String
        /// All language codes available for this tag repository.
        public let availableLanguageCodes: [String]
        /// Id uniquely identifying the tag detail object.
        public let detailId: UUID
        /// The status of the tag detail.
        public let status: Status?
        
        /// Creates a tag detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the tag repository.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        ///   - availableLanguageCodes: All language codes available for this tag repository.
        ///   - detailId: Id uniquely identifying the tag detail object.
        /// - Returns: A tag detail object
        public static func publicDetail(id: UUID, title: String, slug: String, keywords: [String], languageCode: String, availableLanguageCodes: [String], detailId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                slug: slug,
                keywords: keywords,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                detailId: detailId
            )
        }
        
        /// Creates a tag detail object for moderators.
        /// - Parameters:
        ///   - id: Id uniquely identifying the tag repository.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        ///   - availableLanguageCodes: All language codes available for this tag repository.
        ///   - detailId: Id uniquely identifying the tag detail object.
        ///   - status: The status of the tag detail.
        /// - Returns: A tag detail object
        public static func moderatorDetail(id: UUID, title: String, slug: String, keywords: [String], languageCode: String, availableLanguageCodes: [String], detailId: UUID, status: Status) -> Self {
            return .init(
                id: id,
                title: title,
                slug: slug,
                keywords: keywords,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                detailId: detailId,
                status: status
            )
        }
        
        /// Creates a tag detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the tag repository.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        ///   - availableLanguageCodes: All language codes available for this tag repository.
        ///   - detailId: Id uniquely identifying the tag detail object.
        private init(id: UUID, title: String, slug: String, keywords: [String], languageCode: String, availableLanguageCodes: [String], detailId: UUID) {
            self.id = id
            self.title = title
            self.slug = slug
            self.keywords = keywords
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailId = detailId
            self.status = nil
        }
        
        /// Creates a tag detail object for moderators.
        /// - Parameters:
        ///   - id: Id uniquely identifying the tag repository.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        ///   - availableLanguageCodes: All language codes available for this tag repository.
        ///   - detailId: Id uniquely identifying the tag detail object.
        ///   - status: The status of the tag detail.
        private init(id: UUID, title: String, slug: String, keywords: [String], languageCode: String, availableLanguageCodes: [String], detailId: UUID, status: Status) {
            self.id = id
            self.title = title
            self.slug = slug
            self.keywords = keywords
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailId = detailId
            self.status = status
        }
    }
    
    /// Used to create tag objects.
    struct Create: Codable {
        /// The tag title.
        public let title: String
        /// The keywords connected to this tag.
        public let keywords: [String]
        /// The language code for the tag title and keywords.
        public let languageCode: String
        
        /// Creates a tag create object.
        /// - Parameters:
        ///   - title: The tag title.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        public init(title: String, keywords: [String], languageCode: String) {
            self.title = title
            self.keywords = keywords
            self.languageCode = languageCode
        }
    }
    
    /// Used to update tag objects.
    struct Update: Codable {
        /// The tag title.
        public let title: String
        /// The keywords connected to this tag.
        public let keywords: [String]
        /// The language code for the tag title and keywords.
        public let languageCode: String
        
        /// Creates a tag update object.
        /// - Parameters:
        ///   - title: The tag title.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        public init(title: String, keywords: [String], languageCode: String) {
            self.title = title
            self.keywords = keywords
            self.languageCode = languageCode
        }
    }
    
    /// Used to patch tag objects.
    struct Patch: Codable {
        /// The tag title.
        public let title: String?
        /// The keywords connected to this tag.
        public let keywords: [String]?
        /// The language code for the tag title and keywords.
        public let idForTagDetailToPatch: UUID
        
        /// Creates a tag patch object.
        /// - Parameters:
        ///   - title: The tag title.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        public init(title: String?, keywords: [String]?, idForTagDetailToPatch: UUID) {
            self.title = title
            self.keywords = keywords
            self.idForTagDetailToPatch = idForTagDetailToPatch
        }
    }
}
