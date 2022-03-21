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
        public let languageCode: String
        public let verified: Bool?
        public let modelId: UUID?
        public let locationId: UUID?
        
        public static func publicDetail(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                location: location,
                languageCode: languageCode
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String, verified: Bool, modelId: UUID, locationId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                location: location,
                languageCode: languageCode,
                verified: verified,
                modelId: modelId,
                locationId: locationId
            )
        }
        
        private init(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String) {
            self.id = id
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
            self.verified = nil
            self.modelId = nil
            self.locationId = nil
        }
        
        private init(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String, verified: Bool, modelId: UUID, locationId: UUID) {
            self.id = id
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
            self.verified = verified
            self.modelId = modelId
            self.locationId = locationId
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        public let languageCode: String
        
        public init(title: String, description: String, location: Waypoint.Location, languageCode: String) {
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let description: String
        public let languageCode: String
        
        public init(title: String, description: String, languageCode: String) {
            self.title = title
            self.description = description
            self.languageCode = languageCode
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let description: String?
        public let location: Waypoint.Location?
        public let languageCode: String
        
        public init(title: String?, description: String?, location: Waypoint.Location?, languageCode: String) {
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
        }
    }
}
