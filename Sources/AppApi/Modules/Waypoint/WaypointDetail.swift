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
        public let availableLanguageCodes: [String]
        public let detailStatus: Status?
        public let locationStatus: Status?
        public let detailId: UUID?
        public let locationId: UUID?
        
        public static func publicDetail(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, availableLanguageCodes: [String]) -> Self {
            return .init(
                id: id,
                title: title,
                slug: slug,
                detailText: detailText,
                location: location,
                tags: tags,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, availableLanguageCodes: [String], detailStatus: Status, locationStatus: Status, detailId: UUID, locationId: UUID) -> Self {
            return .init(
                id: id,
                title: title,
                slug: slug,
                detailText: detailText,
                location: location,
                tags: tags,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                detailStatus: detailStatus,
                locationStatus: locationStatus,
                detailId: detailId,
                locationId: locationId
            )
        }
        
        private init(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, availableLanguageCodes: [String]) {
            self.id = id
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.location = location
            self.tags = tags
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailStatus = nil
            self.locationStatus = nil
            self.detailId = nil
            self.locationId = nil
        }
        
        private init(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, availableLanguageCodes: [String], detailStatus: Status, locationStatus: Status, detailId: UUID, locationId: UUID) {
            self.id = id
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.location = location
            self.tags = tags
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailStatus = detailStatus
            self.locationStatus = locationStatus
            self.detailId = detailId
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
