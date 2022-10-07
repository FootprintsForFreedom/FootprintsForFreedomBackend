//
//  ElasticStemmer.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

enum ElasticStemmer: String, CustomElasticFilter {
    case arabic
    case armenian
    case basque
    case bengali
    case bulgarian
    case catalan
    case czech
    case danish
    case dutch
    case english
    case englishPossessive = "possessive_english"
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
    case portuguese
    case romanian
    case russian
    case spanish
    case swedish
    case turkish
    
    var light: Bool {
        switch self {
        case .french, .german, .italian, .portuguese, .spanish: return true
        default: return false
        }
    }
    
    var name: String {
        "\(self.rawValue)_\(Self.default)"
    }
    
    static var `default` = "stemmer"
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "language": light ? "light_\(self.rawValue)" : self.rawValue
            ]
        ]
    }
}
