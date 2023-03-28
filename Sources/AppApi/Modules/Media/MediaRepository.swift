//
//  MediaRepository.swift
//  
//
//  Created by niklhut on 17.05.22.
//

import Foundation
import SwiftDiff

public extension Media {
    /// Contains the media repository data transfer objects.
    enum Repository: ApiModelInterface {
        public typealias Module = AppApi.Media
    }
}

public extension Media.Repository {
    /// Used to list unverified media objects.
    struct ListUnverified: Codable {
        /// Id uniquely identifying the media detail object.
        public let detailId: UUID
        /// The media title.
        public let title: String
        /// The slug uniquely identifying the media.
        public let slug: String
        /// The detail text describing the media.
        public let detailText: String
        /// The language code for the media title, description and source.
        public let languageCode: String
        
        /// Creates a  list unverified media details object.
        /// - Parameters:
        ///   - detailId: Id uniquely identifying the media detail object.
        ///   - title: The media title.
        ///   - slug: The slug uniquely identifying the media.
        ///   - detailText: The detail text describing the media.
        ///   - languageCode: The language code for the media title, description and source.
        public init(detailId: UUID, title: String, slug: String, detailText: String, languageCode: String) {
            self.detailId = detailId
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.languageCode = languageCode
        }
    }
    
    /// Used to detail changes between two media objects.
    struct Changes: Codable {
        /// The differences between the titles of the detail objects.
        public let titleDiff: [Diff]
        /// The differences between the detail texts of the detail objects.
        public let detailTextDiff: [Diff]
        /// The differences between the sources of the detail objects.
        public let sourceDiff: [Diff]
        /// The media file group of the source detail object.
        public let fromGroup: Media.Detail.Group
        /// The media file group of the destination detail object.
        public let toGroup: Media.Detail.Group
        /// The file path of the source detail object.
        public let fromFilePath: String
        /// The file path of the destination detail object.
        public let toFilePath: String
        /// The user who created the source detail object.
        public let fromUser: User.Account.Detail?
        /// The user who created the destination detail object.
        public let toUser: User.Account.Detail?
        
        /// Creates a media changes object.
        /// - Parameters:
        ///   - titleDiff: The differences between the titles of the detail objects.
        ///   - detailTextDiff: The differences between the detail texts of the detail objects.
        ///   - sourceDiff: The differences between the sources of the detail objects.
        ///   - fromGroup: The media file group of the source detail object.
        ///   - toGroup: The media file group of the destination detail object.
        ///   - fromFilePath: The file path of the source detail object.
        ///   - toFilePath: The file path of the destination detail object.
        ///   - fromUser: The user who created the source detail object.
        ///   - toUser: The user who created the destination detail object.
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
