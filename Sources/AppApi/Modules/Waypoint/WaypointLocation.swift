//
//  WaypointLocation.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Foundation

public extension Waypoint {
    /// A location object for coordinates.
    struct Location: ApiModelInterface, Codable, Equatable {
        public typealias Module = AppApi.Waypoint
        /// The latitude of the location.
        public let latitude: Double
        /// The longitude of the location.
        public let longitude: Double
        
        /// Creates a location object.
        /// - Parameters:
        ///   - latitude: The latitude of the location.
        ///   - longitude: The longitude of the location.
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}
