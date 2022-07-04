//
//  TagRepository.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Foundation
import SwiftDiff

public extension Tag {
    enum Repository: ApiModelInterface {
        public typealias Module = AppApi.Tag
    }
}

public extension Tag.Repository {
    struct ListUnverified: Codable {
        public let detailId: UUID
        public let title: String
        public let slug: String
        public let keywords: [String]
        public let languageCode: String
        
        public init(detailId: UUID, title: String, slug: String, keywords: [String], languageCode: String) {
            self.detailId = detailId
            self.title = title
            self.slug = slug
            self.keywords = keywords
            self.languageCode = languageCode
        }
    }
    
    struct Changes: Codable {
        public let titleDiff: [Diff]
        public let equalKeywords: [String]
        public let deletedKeywords: [String]
        public let insertedKeywords: [String]
        public let fromUser: User.Account.Detail?
        public let toUser: User.Account.Detail?
        
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
