//
//  WaypointRepository.swift
//  
//
//  Created by niklhut on 21.03.22.
//

import Foundation
import SwiftDiff

public extension Waypoint {
    /// Contains the waypoint repository data transfer objects.
    enum Repository: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Repository {
    /// Used to list unverified waypoints.
    struct ListUnverifiedWaypoints: Codable {
        /// Id uniquely identifying the waypoint detail object.
        public let detailId: UUID
        /// The waypoint title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        /// The detail text describing the waypoint.
        public let detailText: String
        /// The language code for the waypoint title and description.
        public let languageCode: String
        
        /// Creates a list unverified waypoint details object.
        /// - Parameters:
        ///   - detailId: Id uniquely identifying the waypoint detail object.
        ///   - title: The waypoint title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - detailText: The detail text describing the waypoint.
        ///   - languageCode: The language code for the waypoint title and description.
        public init(detailId: UUID, title: String, slug: String, detailText: String, languageCode: String) {
            self.detailId = detailId
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.languageCode = languageCode
        }
    }
    
    /// Used to list unverified locations.
    struct ListUnverifiedLocations: Codable {
        /// Id uniquely identifying the location object.
        public let locationId: UUID
        /// The location.
        public let location: Waypoint.Location
        
        /// Creates a list unverified locations object.
        /// - Parameters:
        ///   - locationId: Id uniquely identifying the location object.
        ///   - location: The location.
        public init(locationId: UUID, location: Waypoint.Location) {
            self.locationId = locationId
            self.location = location
        }
    }
    
    /// Used to detail changes between two waypoint objects.
    struct Changes: Codable {
        /// The differences between the titles of the detail objects.
        public let titleDiff: [Diff]
        /// The differences between the detail texts of the detail objects.
        public let detailTextDiff: [Diff]
        /// The user who created the source detail object.
        public let fromUser: User.Account.Detail?
        /// The user who created the destination detail object.
        public let toUser: User.Account.Detail?
        
        /// Creates a waypoint changes object.
        /// - Parameters:
        ///   - titleDiff: The differences between the titles of the detail objects.
        ///   - detailTextDiff: The differences between the detail texts of the detail objects.
        ///   - fromUser: The user who created the source detail object.
        ///   - toUser: The user who created the destination detail object.
        public init(titleDiff: [Diff], detailTextDiff: [Diff], fromUser: User.Account.Detail?, toUser: User.Account.Detail?) {
            self.titleDiff = titleDiff
            self.detailTextDiff = detailTextDiff
            self.fromUser = fromUser
            self.toUser = toUser
        }
    }
}
