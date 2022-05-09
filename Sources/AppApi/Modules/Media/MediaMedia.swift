//
//  MediaMedia.swift
//  
//
//  Created by niklhut on 09.05.22.
//

// TODO: remove Vapor, instead use own File struct (don't forget to remove it form Package.swift as well)
import Vapor

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
        public let title: String
        public let description: String
        public let source: String
        public let group: Group
        public let filePath: String
        public let verified: Bool?
        
        public static func publicDetail(id: UUID, title: String, description: String, source: String, group: Group, filePath: String) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                source: source,
                group: group,
                filePath: filePath
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, description: String, source: String, group: Group, filePath: String, verified: Bool) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                source: source,
                group: group,
                filePath: filePath,
                verified: verified
            )
        }
        
        private init(id: UUID, title: String, description: String, source: String, group: Group, filePath: String) {
            self.id = id
            self.title = title
            self.description = description
            self.source = source
            self.group = group
            self.filePath = filePath
            self.verified = nil
        }
        
        private init(id: UUID, title: String, description: String, source: String, group: Group, filePath: String, verified: Bool) {
            self.id = id
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
        public let file: File
        
        public init(title: String, description: String, source: String, file: File) {
            self.title = title
            self.description = description
            self.source = source
            self.file = file
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let description: String
        public let source: String
        
        public init(title: String, description: String, source: String) {
            self.title = title
            self.description = description
            self.source = source
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let description: String?
        public let source: String?
        
        public init(title: String?, description: String?, source: String?) {
            self.title = title
            self.description = description
            self.source = source
        }
    }
}
