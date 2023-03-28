//
//  WaypointLocationValidation.swift
//  
//
//  Created by niklhut on 19.02.22.
//

import AppApi

extension KeyedContentValidator where T == Waypoint.Location {
    static func location(_ key: String, _ message: String? = nil, optional: Bool = false) -> KeyedContentValidator<T> {
        .init(key, "\(key.capitalized) is required", optional: optional) { value, request in
            value.latitude >= -90 &&
            value.latitude <= 90 &&
            value.longitude >= -180 &&
            value.longitude <= 180
        }
    }
}
