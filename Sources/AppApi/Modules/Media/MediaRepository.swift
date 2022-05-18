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
    struct DetailChangesRequest: Codable {
        public let from: UUID
        public let to: UUID
        
        public init(from: UUID, to: UUID) {
            self.from = from
            self.to = to
        }
    }
    
    struct ListUnverified: Codable {
        public let modelId: UUID
        public let title: String
        public let description: String
        public let languageCode: String
        
        public init(modelId: UUID, title: String, description: String, languageCode: String) {
            self.modelId = modelId
            self.title = title
            self.description = description
            self.languageCode = languageCode
        }
    }
    
    struct Changes: Codable {
        public let titleDiff: [Diff]
        public let descriptionDiff: [Diff]
        public let sourceDiff: [Diff]
        public let fromGroup: Media.Media.Group
        public let toGroup: Media.Media.Group
        public let fromFilePath: String
        public let toFilePath: String
        public let fromUser: User.Account.Detail
        public let toUser: User.Account.Detail
        
        public init(titleDiff: [Diff], descriptionDiff: [Diff], sourceDiff: [Diff], fromGroup: Media.Media.Group, toGroup: Media.Media.Group, fromFilePath: String, toFilePath: String, fromUser: User.Account.Detail, toUser: User.Account.Detail) {
            self.titleDiff = titleDiff
            self.descriptionDiff = descriptionDiff
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