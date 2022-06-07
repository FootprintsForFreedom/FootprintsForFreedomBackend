//
//  WaypointDetail.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Foundation

public extension Waypoint {
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Detail {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let slug: String
        public let location: Waypoint.Location
        
        public init(id: UUID, title: String, slug: String, location: Waypoint.Location) {
            self.id = id
            self.title = title
            self.location = location
            self.slug = slug
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let title: String
        public let slug: String
        public let detailText: String
        public let location: Waypoint.Location
        public let tags: [Tag.Detail.List]
        public let languageCode: String
        public let detailStatus: Status?
        public let locationStatus: Status?
        public let modelId: UUID?
        public let locationId: UUID?
        
        public static func publicDetail(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String) -> Self {
            return .init(
                id: id,
                title: title,
                slug: slug,
                detailText: detailText,
                location: location,
                tags: tags,
                languageCode: languageCode
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, detailStatus: Status, locationStatus: Status, modelId: UUID, locationId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                slug: slug,
                detailText: detailText,
                location: location,
                tags: tags,
                languageCode: languageCode,
                detailStatus: detailStatus,
                locationStatus: locationStatus,
                modelId: modelId,
                locationId: locationId
            )
        }
        
        private init(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String) {
            self.id = id
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.location = location
            self.tags = tags
            self.languageCode = languageCode
            self.detailStatus = nil
            self.locationStatus = nil
            self.modelId = nil
            self.locationId = nil
        }
        
        private init(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, detailStatus: Status, locationStatus: Status, modelId: UUID, locationId: UUID) {
            self.id = id
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.location = location
            self.tags = tags
            self.languageCode = languageCode
            self.detailStatus = detailStatus
            self.locationStatus = locationStatus
            self.modelId = modelId
            self.locationId = locationId
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let detailText: String
        public let location: Waypoint.Location
        public let languageCode: String
        
        public init(title: String, detailText: String, location: Waypoint.Location, languageCode: String) {
            self.title = title
            self.detailText = detailText
            self.location = location
            self.languageCode = languageCode
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let detailText: String
        public let languageCode: String
        
        public init(title: String, detailText: String, languageCode: String) {
            self.title = title
            self.detailText = detailText
            self.languageCode = languageCode
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let detailText: String?
        public let location: Waypoint.Location?
        public let idForWaypointToPatch: UUID
        
        public init(title: String?, detailText: String?, location: Waypoint.Location?, idForWaypointToPatch: UUID) {
            self.title = title
            self.detailText = detailText
            self.location = location
            self.idForWaypointToPatch = idForWaypointToPatch
        }
    }
}
