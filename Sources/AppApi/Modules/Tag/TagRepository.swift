//
//  TagRepository.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Foundation
import SwiftDiff

public extension Tag {
    /// Contains the tag repository data transfer objects.
    enum Repository: ApiModelInterface {
        public typealias Module = AppApi.Tag
    }
}

public extension Tag.Repository {
    /// Used to list unverified tags.
    struct ListUnverified: Codable {
        /// Id uniquely identifying the tag detail object.
        public let detailId: UUID
        /// The tag title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        /// The keywords connected to this tag.
        public let keywords: [String]
        /// The language code for the tag title and keywords.
        public let languageCode: String
        
        /// Creates a list unverified tags object.
        /// - Parameters:
        ///   - detailId: Id uniquely identifying the tag detail object.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - keywords: The keywords connected to this tag.
        ///   - languageCode: The language code for the tag title and keywords.
        public init(detailId: UUID, title: String, slug: String, keywords: [String], languageCode: String) {
            self.detailId = detailId
            self.title = title
            self.slug = slug
            self.keywords = keywords
            self.languageCode = languageCode
        }
    }
    
    /// Used to list unverified tags.
    struct ListUnverifiedRelation: Codable {
        /// Id uniquely identifying the tag repository.
        public let tagId: UUID
        /// The tag title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        /// The status of the tag to waypoint connection.
        public let status: Status
        /// The language code for the tag title and keywords.
        public let languageCode: String
        
        /// Creates a list unverified tags object.
        /// - Parameters:
        ///   - detailId: Id uniquely identifying the tag detail object.
        ///   - title: The tag title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - status: The status of the tag to waypoint connection.
        ///   - languageCode: The language code for the tag.
        public init(tagId: UUID, title: String, slug: String, status: Status, languageCode: String) {
            self.tagId = tagId
            self.title = title
            self.slug = slug
            self.status = status
            self.languageCode = languageCode
        }
    }
    
    /// Used to detail changes between two tag objects.
    struct Changes: Codable {
        /// The differences between the titles of the detail objects.
        public let titleDiff: [Diff]
        /// The unchanged keywords.
        public let equalKeywords: [String]
        /// The removed keywords.
        public let deletedKeywords: [String]
        /// The added keywords.
        public let insertedKeywords: [String]
        /// The user who created the source detail object.
        public let fromUser: User.Account.Detail?
        /// The user who created the destination detail object.
        public let toUser: User.Account.Detail?
        
        /// Creates a tag changes object.
        /// - Parameters:
        ///   - titleDiff: The differences between the titles of the detail objects.
        ///   - equalKeywords: The unchanged keywords.
        ///   - deletedKeywords: The removed keywords.
        ///   - insertedKeywords: The added keywords.
        ///   - fromUser: The user who created the source detail object.
        ///   - toUser: The user who created the destination detail object.
        public init(titleDiff: [Diff], equalKeywords: [String], deletedKeywords: [String], insertedKeywords: [String], fromUser: User.Account.Detail?, toUser: User.Account.Detail?) {
            self.titleDiff = titleDiff
            self.equalKeywords = equalKeywords
            self.deletedKeywords = deletedKeywords
            self.insertedKeywords = insertedKeywords
            self.fromUser = fromUser
            self.toUser = toUser
        }
    }
}
