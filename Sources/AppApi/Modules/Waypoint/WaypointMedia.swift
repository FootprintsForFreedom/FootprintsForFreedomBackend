//
//  File.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Vapor
import Foundation

public extension Waypoint {
    enum Media: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Media {
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
        public let createdAt: Date?
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
        
        public static func moderatorDetail(id: UUID, title: String, description: String, source: String, group: Group, filePath: String, createdAt: Date, verified: Bool) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                source: source,
                group: group,
                filePath: filePath,
                createdAt: createdAt,
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
            self.createdAt = nil
            self.verified = nil
        }
        
        private init(id: UUID, title: String, description: String, source: String, group: Group, filePath: String, createdAt: Date, verified: Bool) {
            self.id = id
            self.title = title
            self.description = description
            self.source = source
            self.group = group
            self.filePath = filePath
            self.createdAt = createdAt
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
