//
//  File.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Vapor
import Fluent

final class WaypointLocationFields: Fields {
    
    struct FieldKeys {
        struct v1 {
            static var latitude: FieldKey { "latitude" }
            static var longitude: FieldKey { "longitude" }
        }
    }
    
    @Field(key: FieldKeys.v1.latitude) var latitude: Double
    @Field(key: FieldKeys.v1.longitude) var longitude: Double
    
    init() { }
    
    init(
        latitude: Double,
        longitude: Double
    ) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
