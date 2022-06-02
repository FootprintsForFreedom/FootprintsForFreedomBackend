//
//  MediaRepository.swift
//  
//
//  Created by niklhut on 17.05.22.
//

import Foundation
import DiffMatchPatch

public extension Media {
    enum Repository: ApiModelInterface {
        public typealias Module = AppApi.Media
    }
}

public extension Media.Repository {
    struct ListUnverified: Codable {
        public let modelId: UUID
        public let title: String
        public let detailText: String
        public let languageCode: String
        
        public init(modelId: UUID, title: String, detailText: String, languageCode: String) {
            self.modelId = modelId
            self.title = title
            self.detailText = detailText
            self.languageCode = languageCode
        }
    }
    
    enum ChangeAction: Codable {
        case verify, delete
    }
    
    struct ListUnverifiedTags: Codable {
        public let tagId: UUID
        public let title: String
        public let changeAction: ChangeAction
        
        public init(tagId: UUID, title: String, changeAction: ChangeAction) {
            self.tagId = tagId
            self.title = title
            self.changeAction = changeAction
        }
    }
    
    struct Changes: Codable {
        public let titleDiff: [Diff]
        public let detailTextDiff: [Diff]
        public let sourceDiff: [Diff]
        public let fromGroup: Media.Detail.Group
        public let toGroup: Media.Detail.Group
        public let fromFilePath: String
        public let toFilePath: String
        public let fromUser: User.Account.Detail?
        public let toUser: User.Account.Detail?
        
        public init(titleDiff: [Diff], detailTextDiff: [Diff], sourceDiff: [Diff], fromGroup: Media.Detail.Group, toGroup: Media.Detail.Group, fromFilePath: String, toFilePath: String, fromUser: User.Account.Detail?, toUser: User.Account.Detail?) {
            self.titleDiff = titleDiff
            self.detailTextDiff = detailTextDiff
            self.sourceDiff = sourceDiff
            self.fromGroup = fromGroup
            self.toGroup = toGroup
            self.fromFilePath = fromFilePath
            self.toFilePath = toFilePath
            self.fromUser = fromUser
            self.toUser = toUser
        }
    }
}
