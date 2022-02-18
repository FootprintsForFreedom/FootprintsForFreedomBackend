//
//  WaypointLocation.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Foundation

public extension Waypoint {
    struct Location: ApiModelInterface, Codable, Equatable {
        public typealias Module = AppApi.Waypoint
        public let latitude: Double
        public let longitude: Double
        
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}
