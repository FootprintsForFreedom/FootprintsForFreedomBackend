//
//  ElasticLowercase.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

enum ElasticLowercase: String, CustomElasticFilter {
    case greek
    case irish
    case turkish
    
    var name: String {
        "\(self.rawValue)_\(Self.default)"
    }
    
    static var `default` = "lowercase"
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "language": self.rawValue
            ]
        ]
    }
}

