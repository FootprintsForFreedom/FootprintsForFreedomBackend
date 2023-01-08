//
//  WaypointDetail.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Foundation

public extension Waypoint {
    /// Contains the waypoint detail data transfer objects.
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Detail {
    /// Used to request a list of waypoint objects. The location specifies the area for which results should be listed.
    ///
    /// - Note: If no valid location is enclosed the request handler will try to resolve the user's location by its ip address and otherwise fall back to a default value.
    struct GetList: Codable {
        /// The latitude of the area in which the user is. If unavailable set to nil.
        public let latitude: Double?
        /// The longitude of the area in which the user is. If unavailable set to nil.
        public let longitude: Double?
        
        /// Used to request a list of waypoint objects.
        /// - Parameters:
        ///   - latitude: The latitude of the area in which the user is. If unavailable set to nil.
        ///   - longitude: The longitude of the area in which the user is. If unavailable set to nil.
        public init(latitude: Double?, longitude: Double?) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    /// Used to list waypoint objects with a user location.
    ///
    /// Contains ``Waypoint/Location`` as as user location and ``List`` items as ``Subset`` near this location.
    struct ListWrapper: Codable {
        /// The location of the user sending the initial ``Waypoint/Detail/GetList`` request.
        ///
        /// If the ``Waypoint/Detail/GetList`` request already contained a location, this is going to be the same one.
        ///
        /// Otherwise the approximate location is derived from the users ip address. If no location can be found for the user's ip address a default value will be used.
        ///
        /// - Note: The items enclosed will be sorted to be near this location.
        public let userLocation: Waypoint.Location
        /// A ``Subset`` of ``Waypoint/Detail/List`` items near the user's location.
        public let items: Subset<List>
        
        
        /// Used to list waypoint objects with a user location.
        /// - Parameters:
        ///   - userLocation: The location of the user sending the initial ``Waypoint/Detail/GetList`` request.
        ///   - items: A ``Subset`` of ``Waypoint/Detail/List`` items near the user's location.
        public init(userLocation: Waypoint.Location, items: Subset<List>) {
            self.userLocation = userLocation
            self.items = items
        }
    }
    
    /// Used to list waypoint objects.
    struct List: Codable {
        /// Id uniquely identifying the waypoint repository.
        public let id: UUID
        /// The waypoint title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        /// The location of the waypoint.
        public let location: Waypoint.Location
        
        /// Creates a waypoint list object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the waypoint repository.
        ///   - title: The waypoint title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - location: The location of the waypoint.
        public init(id: UUID, title: String, slug: String, location: Waypoint.Location) {
            self.id = id
            self.title = title
            self.location = location
            self.slug = slug
        }
    }
    
    /// Used to detail waypoint objects.
    struct Detail: Codable {
        /// Id uniquely identifying the waypoint repository.
        public let id: UUID
        /// The waypoint title.
        public let title: String
        /// The slug uniquely identifying the waypoint.
        public let slug: String
        /// The detail text describing the waypoint.
        public let detailText: String
        /// The location of the waypoint.
        public let location: Waypoint.Location
        /// The tags connected with this waypoint.
        public let tags: [Tag.Detail.List]
        /// The language code for the waypoint title and description.
        public let languageCode: String
        /// All language codes available for this waypoint repository.
        public let availableLanguageCodes: [String]
        /// Id uniquely identifying the waypoint detail object.
        public let detailId: UUID
        /// Id uniquely identifying the location object.
        public let locationId: UUID
        
        /// Creates a waypoint detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the waypoint repository.
        ///   - title: The waypoint title.
        ///   - slug: The slug uniquely identifying the waypoint.
        ///   - detailText: The detail text describing the waypoint.
        ///   - location: The location of the waypoint.
        ///   - tags: The tags connected with this waypoint.
        ///   - languageCode: The language code for the waypoint title and description.
        ///   - availableLanguageCodes: All language codes available for this waypoint repository.
        ///   - detailId: Id uniquely identifying the waypoint detail object.
        ///   - locationId: Id uniquely identifying the location object.
        public init(id: UUID, title: String, slug: String, detailText: String, location: Waypoint.Location, tags: [Tag.Detail.List], languageCode: String, availableLanguageCodes: [String], detailId: UUID, locationId: UUID) {
            self.id = id
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.location = location
            self.tags = tags
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
            self.detailId = detailId
            self.locationId = locationId
        }
    }
    
    /// Used to create waypoint objects.
    struct Create: Codable {
        /// The waypoint title.
        public let title: String
        /// The detail text describing the waypoint.
        public let detailText: String
        /// The location of the waypoint.
        public let location: Waypoint.Location
        /// The language code for the waypoint title and description.
        public let languageCode: String
        
        /// Creates a waypoint create object.
        /// - Parameters:
        ///   - title: The waypoint title.
        ///   - detailText: The detail text describing the waypoint.
        ///   - location: The location of the waypoint.
        ///   - languageCode: The language code for the waypoint title and description.
        public init(title: String, detailText: String, location: Waypoint.Location, languageCode: String) {
            self.title = title
            self.detailText = detailText
            self.location = location
            self.languageCode = languageCode
        }
    }
    
    /// Used to update waypoint objects.
    struct Update: Codable {
        /// The waypoint title.
        public let title: String
        /// The detail text describing the waypoint.
        public let detailText: String
        /// The language code for the waypoint title and description.
        public let languageCode: String
        
        /// Creates a waypoint update object.
        /// - Parameters:
        ///   - title: The waypoint title.
        ///   - detailText: The detail text describing the waypoint.
        ///   - languageCode: The language code for the waypoint title and description.
        public init(title: String, detailText: String, languageCode: String) {
            self.title = title
            self.detailText = detailText
            self.languageCode = languageCode
        }
    }
    
    /// Used to patch waypoint objects.
    struct Patch: Codable {
        /// The waypoint title.
        public let title: String?
        /// The detail text describing the waypoint.
        public let detailText: String?
        /// The location of the waypoint.
        public let location: Waypoint.Location?
        /// The id of an existing waypoint. All parameters not set in this request will be taken from this waypoint.
        public let idForWaypointDetailToPatch: UUID
        
        /// Creates a waypoint patch object
        /// - Parameters:
        ///   - title: The waypoint title.
        ///   - detailText: The detail text describing the waypoint.
        ///   - location: The location of the waypoint.
        ///   - idForWaypointDetailToPatch: The id of an existing waypoint. All parameters not set in this request will be taken from this waypoint.
        public init(title: String?, detailText: String?, location: Waypoint.Location?, idForWaypointDetailToPatch: UUID) {
            self.title = title
            self.detailText = detailText
            self.location = location
            self.idForWaypointDetailToPatch = idForWaypointDetailToPatch
        }
    }
}
