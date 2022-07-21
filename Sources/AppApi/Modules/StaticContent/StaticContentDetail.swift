//
//  StaticContentDetail.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Foundation

public extension StaticContent {
    /// Contains the static content detail data transfer objects.
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.StaticContent
    }
}

public extension StaticContent.Detail {
    /// Used to list static content objects.
    struct List: Codable {
        /// Id uniquely identifying the static content repository.
        public let id: UUID
        /// Slug uniquely identifying the static content repository.
        public let slug: String
        
        public init(id: UUID, slug: String) {
            self.id = id
            self.slug = slug
        }
    }
    
    /// Used to detail static content objects.
    struct Detail: Codable {
        /// Id uniquely identifying the static content repository.
        public let id: UUID
        /// The localized title visible to users. It can also contain snippets.
        public let title: String
        /// The localized text visible to users. If any snippets are required this text needs to contain those.
        public let text: String
        /// The language code for the static content.
        public let languageCode: String
        /// All language codes available for this static content repository.
        public let availableLanguageCodes: [String]
        /// Id uniquely identifying the static content detail object.
        public let detailId: UUID
        /// The localized title describing the the static content to a moderator.
        public let moderationTitle: String?
        /// An array containing all snippets which are required for this static content.
        public let requiredSnippets: [StaticContent.Snippet]?
        
        /// Creates a static content detail object for admins.
        /// - Parameters:
        ///   - id: Id uniquely identifying the static content repository.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - languageCode: The language code for the static content.
        ///   - availableLanguageCodes: All language codes available for this static content repository.
        ///   - detailId: Id uniquely identifying the static content detail object.
        /// - Returns: A static content detail object.
        public static func publicDetail(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String], detailId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                text: text,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                detailId: detailId
            )
        }
        
        /// Creates a static content detail object for admins.
        /// - Parameters:
        ///   - id: Id uniquely identifying the static content repository.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - languageCode: The language code for the static content.
        ///   - availableLanguageCodes: All language codes available for this static content repository.
        ///   - moderationTitle: The localized title describing the the static content to a moderator.
        ///   - requiredSnippets: An array containing all snippets which are required for this static content.
        ///   - detailId: Id uniquely identifying the static content detail object.
        /// - Returns: A static content detail object.
        public static func administratorDetail(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String], detailId: UUID, moderationTitle: String?, requiredSnippets: [StaticContent.Snippet]?) -> Self {
            return .init(
                id: id,
                title: title,
                text: text,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                detailId: detailId,
                moderationTitle: moderationTitle,
                requiredSnippets: requiredSnippets
            )
        }
        
        /// Creates a static content detail object for admins.
        /// - Parameters:
        ///   - id: Id uniquely identifying the static content repository.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - languageCode: The language code for the static content.
        ///   - availableLanguageCodes: All language codes available for this static content repository.
        ///   - detailId: Id uniquely identifying the static content detail object.
        private init(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String], detailId: UUID) {
            self.id = id
            self.title = title
            self.text = text
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailId = detailId
            self.moderationTitle = nil
            self.requiredSnippets = nil
        }
        
        /// Creates a static content detail object for admins.
        /// - Parameters:
        ///   - id: Id uniquely identifying the static content repository.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - languageCode: The language code for the static content.
        ///   - availableLanguageCodes: All language codes available for this static content repository.
        ///   - moderationTitle: The localized title describing the the static content to a moderator.
        ///   - requiredSnippets: An array containing all snippets which are required for this static content.
        ///   - detailId: Id uniquely identifying the static content detail object.
        private init(id: UUID, title: String, text: String, languageCode: String, availableLanguageCodes: [String], detailId: UUID, moderationTitle: String?, requiredSnippets: [StaticContent.Snippet]?) {
            self.id = id
            self.title = title
            self.text = text
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailId = detailId
            self.moderationTitle = moderationTitle
            self.requiredSnippets = requiredSnippets
        }
    }
    
    /// Used to create static content objects.
    struct Create: Codable {
        /// A title uniquely identifying the static content repository. Preferably in english.
        public let repositoryTitle: String
        /// The localized title describing the the static content to a moderator.
        public let moderationTitle: String
        /// The localized title visible to users. It can also contain snippets.
        public let title: String
        /// The localized text visible to users. If any snippets are required this text needs to contain those.
        public let text: String
        /// An array containing all snippets which are required for this static content.
        public let requiredSnippets: [StaticContent.Snippet]?
        /// The language code for the static content.
        public let languageCode: String
        
        /// Creates a static content create object.
        /// - Parameters:
        ///   - repositoryTitle: A title uniquely identifying the static content repository. Preferably in english.
        ///   - moderationTitle: The localized title describing the the static content to a moderator.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - requiredSnippets: An array containing all snippets which are required for this static content.
        ///   - languageCode: The language code for the static content.
        public init(repositoryTitle: String, moderationTitle: String, title: String, text: String, requiredSnippets: [StaticContent.Snippet]?, languageCode: String) {
            self.repositoryTitle = repositoryTitle
            self.moderationTitle = moderationTitle
            self.title = title
            self.text = text
            self.requiredSnippets = requiredSnippets
            self.languageCode = languageCode
        }
    }
    
    /// Used to update static content objects.
    struct Update: Codable {
        /// The localized title describing the the static content to a moderator.
        public let moderationTitle: String
        /// The localized title visible to users. It can also contain snippets.
        public let title: String
        /// The localized text visible to users. If any snippets are required this text needs to contain those.
        public let text: String
        /// The language code for the static content.
        public let languageCode: String
        
        /// Creates a static content update object.
        /// - Parameters:
        ///   - moderationTitle: The localized title describing the the static content to a moderator.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - languageCode: The language code for the static content.
        public init(moderationTitle: String, title: String, text: String, languageCode: String) {
            self.moderationTitle = moderationTitle
            self.title = title
            self.text = text
            self.languageCode = languageCode
        }
    }
    
    /// Used to patch static content objects.
    struct Patch: Codable {
        /// The localized title describing the the static content to a moderator.
        public let moderationTitle: String?
        /// The localized title visible to users. It can also contain snippets.
        public let title: String?
        /// The localized text visible to users. If any snippets are required this text needs to contain those.
        public let text: String?
        /// The id of an existing static content. All parameters not set in this request will be taken from this static content.
        public let idForStaticContentDetailToPatch: UUID
        
        /// Creates a static content patch object.
        /// - Parameters:
        ///   - moderationTitle: The localized title describing the the static content to a moderator.
        ///   - title: The localized title visible to users. It can also contain snippets.
        ///   - text: The localized text visible to users. If any snippets are required this text needs to contain those.
        ///   - idForStaticContentDetailToPatch: The id of an existing static content. All parameters not set in this request will be taken from this static content.
        public init(moderationTitle: String?, title: String?, text: String?, idForStaticContentDetailToPatch: UUID) {
            self.moderationTitle = moderationTitle
            self.title = title
            self.text = text
            self.idForStaticContentDetailToPatch = idForStaticContentDetailToPatch
        }
    }
}
