//
//  File.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Foundation

public extension Waypoint {
    enum Waypoint: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Waypoint {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let location: Waypoint.Location
        
        public init(id: UUID, title: String, location: Waypoint.Location) {
            self.id = id
            self.title = title
            self.location = location
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        public let verified: Bool?
        
        public static func publicDetail(id: UUID, title: String, description: String, location: Waypoint.Location) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                location: location
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, description: String, location: Waypoint.Location, verified: Bool) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                location: location,
                verified: verified
            )
        }
        
        private init(id: UUID, title: String, description: String, location: Waypoint.Location) {
            self.id = id
            self.title = title
            self.description = description
            self.location = location
            self.verified = nil
        }
        
        private init(id: UUID, title: String, description: String, location: Waypoint.Location, verified: Bool) {
            self.id = id
            self.title = title
            self.description = description
            self.location = location
            self.verified = verified
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        
        public init(title: String, description: String, location: Waypoint.Location) {
            self.title = title
            self.description = description
            self.location = location
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        
        public init(title: String, description: String, location: Waypoint.Location) {
            self.title = title
            self.description = description
            self.location = location
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let description: String?
        public let location: Waypoint.Location?
        
        public init(title: String?, description: String?, location: Waypoint.Location?) {
            self.title = title
            self.description = description
            self.location = location
        }
    }
}
