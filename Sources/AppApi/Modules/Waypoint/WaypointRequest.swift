//
//  WaypointRequest.swift
//  
//
//  Created by niklhut on 31.01.23.
//

import Foundation

public extension Waypoint {
    /// Contains the data transfer objects to request certain waypoints.
    enum Request: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Request {
    /// Used to request a list of waypoint objects. The location specifies the area for which results should be listed.
    ///
    /// - Note: If no valid location is enclosed the request handler will try to resolve the user's location by its ip address and otherwise fall back to a default value.
    struct GetList: Codable {
        /// The latitude of the area in which the user is. If unavailable set to nil.
        public let latitude: Double?
        /// The longitude of the area in which the user is. If unavailable set to nil.
        public let longitude: Double?
        
        /// Creates a waypoint get list request object.
        /// - Parameters:
        ///   - latitude: The latitude of the area in which the user is. If unavailable set to nil.
        ///   - longitude: The longitude of the area in which the user is. If unavailable set to nil.
        public init(latitude: Double?, longitude: Double?) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    /// Used to request a list  of waypoint objects inside a given area.
    ///
    /// The area is limited by two corner coordinates.
    struct ListInArea: Codable {
        /// The top left latitude of the relevant area.
        public let topLeftLatitude: Double
        /// The top left longitude of the relevant area.
        public let topLeftLongitude: Double
        /// The bottom right latitude of the relevant area.
        public let bottomRightLatitude: Double
        /// The bottom right longitude of the relevant area.
        public let bottomRightLongitude: Double
        
        /// Creates a waypoint get in range request object.
        /// - Parameters:
        ///   - topLeftLatitude: The top left latitude of the relevant area.
        ///   - topLeftLongitude: The top left longitude of the relevant area.
        ///   - bottomRightLatitude: The bottom right latitude of the relevant area.
        ///   - bottomRightLongitude: The bottom right longitude of the relevant area.
        public init(topLeftLatitude: Double, topLeftLongitude: Double, bottomRightLatitude: Double, bottomRightLongitude: Double) {
            self.topLeftLatitude = topLeftLatitude
            self.topLeftLongitude = topLeftLongitude
            self.bottomRightLatitude = bottomRightLatitude
            self.bottomRightLongitude = bottomRightLongitude
        }
    }
}
