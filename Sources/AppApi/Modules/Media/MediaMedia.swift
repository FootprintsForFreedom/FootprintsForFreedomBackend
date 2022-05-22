//
//  MediaMedia.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Foundation

public extension Media {
    enum Media: ApiModelInterface {
        public typealias Module = AppApi.Media
    }
}

public extension Media.Media {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let group: Group
        
        public init(id: UUID, title: String, group: Group) {
            self.id = id
            self.title = title
            self.group = group
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let languageCode: String
        public let title: String
        public let detailText: String
        public let source: String
        public let group: Group
        public let filePath: String
        public let verified: Bool?
        public let detailId: UUID?
        
        public static func publicDetail(id: UUID, languageCode: String, title: String, detailText: String, source: String, group: Group, filePath: String) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                title: title,
                detailText: detailText,
                source: source,
                group: group,
                filePath: filePath
            )
        }
        
        public static func moderatorDetail(id: UUID, languageCode: String, title: String, detailText: String, source: String, group: Group, filePath: String, verified: Bool, detailId: UUID) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                title: title,
                detailText: detailText,
                source: source,
                group: group,
                filePath: filePath,
                verified: verified,
                detailId: detailId
            )
        }
        
        private init(id: UUID, languageCode: String, title: String, detailText: String, source: String, group: Group, filePath: String) {
            self.id = id
            self.languageCode = languageCode
            self.title = title
            self.detailText = detailText
            self.source = source
            self.group = group
            self.filePath = filePath
            self.verified = nil
            self.detailId = nil
        }
        
        private init(id: UUID, languageCode: String, title: String, detailText: String, source: String, group: Group, filePath: String, verified: Bool, detailId: UUID) {
            self.id = id
            self.languageCode = languageCode
            self.title = title
            self.detailText = detailText
            self.source = source
            self.group = group
            self.filePath = filePath
            self.verified = verified
            self.detailId = detailId
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let detailText: String
        public let source: String
        public let languageCode: String
        public let waypointId: UUID
        
        public init(title: String, detailText: String, source: String, languageCode: String, waypointId: UUID) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.languageCode = languageCode
            self.waypointId = waypointId
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let detailText: String
        public let source: String
        public let languageCode: String
        public let mediaIdForFile: UUID?
        
        public init(title: String, detailText: String, source: String, languageCode: String, mediaIdForFile: UUID?) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.languageCode = languageCode
            self.mediaIdForFile = mediaIdForFile
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let detailText: String?
        public let source: String?
        public let idForMediaToPatch: UUID
        
        public init(title: String?, detailText: String?, source: String?, idForMediaToPatch: UUID) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.idForMediaToPatch = idForMediaToPatch
        }
    }
}
