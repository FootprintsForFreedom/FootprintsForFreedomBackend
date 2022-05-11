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
        public let description: String
        public let source: String
        public let group: Group
        public let filePath: String
        public let verified: Bool?
        
        public static func publicDetail(id: UUID, languageCode: String, title: String, description: String, source: String, group: Group, filePath: String) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                title: title,
                description: description,
                source: source,
                group: group,
                filePath: filePath
            )
        }
        
        public static func moderatorDetail(id: UUID, languageCode: String, title: String, description: String, source: String, group: Group, filePath: String, verified: Bool) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                title: title,
                description: description,
                source: source,
                group: group,
                filePath: filePath,
                verified: verified
            )
        }
        
        private init(id: UUID, languageCode: String, title: String, description: String, source: String, group: Group, filePath: String) {
            self.id = id
            self.languageCode = languageCode
            self.title = title
            self.description = description
            self.source = source
            self.group = group
            self.filePath = filePath
            self.verified = nil
        }
        
        private init(id: UUID, languageCode: String, title: String, description: String, source: String, group: Group, filePath: String, verified: Bool) {
            self.id = id
            self.languageCode = languageCode
            self.title = title
            self.description = description
            self.source = source
            self.group = group
            self.filePath = filePath
            self.verified = verified
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let description: String
        public let source: String
        public let languageCode: String
        public let waypointId: UUID
        
        public init(title: String, description: String, source: String, languageCode: String, waypointId: UUID) {
            self.title = title
            self.description = description
            self.source = source
            self.languageCode = languageCode
            self.waypointId = waypointId
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let description: String
        public let source: String
        public let languageCode: String
        
        public init(title: String, description: String, source: String, languageCode: String) {
            self.title = title
            self.description = description
            self.source = source
            self.languageCode = languageCode
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let description: String?
        public let source: String?
        public let languageCode: String
        
        public init(title: String?, description: String?, source: String?, languageCode: String) {
            self.title = title
            self.description = description
            self.source = source
            self.languageCode = languageCode
        }
    }
}
