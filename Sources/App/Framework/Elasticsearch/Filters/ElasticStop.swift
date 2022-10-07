//
//  ElasticStop.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

enum ElasticStop: CustomElasticFilter {
    case arabic
    case armenian
    case basque
    case bengali
    case bulgarian
    case catalan
    case cjk
    case czech
    case danish
    case dutch
    case english
    case estonian
    case finnish
    case french
    case galician
    case german
    case greek
    case hindi
    case hungarian
    case indonesian
    case irish
    case italian
    case latvian
    case lithuanian
    case norwegian
    case persian
    case portuguese
    case romanian
    case russian
    case spanish
    case swedish
    case thai
    case turkish
    case custom(name: String, stopwords: [String])
    
    var name: String {
        switch self {
        case .custom(let name, _):
            return "\(name)_stop"
        default:
            return "\(String(describing: self))_stop"
        }
    }
    
    var stopwords: Any {
        switch self {
        case .custom(_, let stopwords): return stopwords
        default: return "_\(String(describing: self))_"
        }
    }
    
    static var `default` = "stop"
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "stopwords": stopwords
            ]
        ]
    }
}
