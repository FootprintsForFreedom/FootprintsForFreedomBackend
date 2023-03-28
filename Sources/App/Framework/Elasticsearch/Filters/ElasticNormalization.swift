//
//  ElasticNormalization.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// A token filter tries to normalize special characters of a certain language.
enum ElasticNormalization: String, DefaultElasticFilter {
    case arabic
    case bengali
    case german
    case hindi
    case indic
    case sorani
    case persian
    case scandinavian
    case serbian
    
    static var `default` = "normalization"
    
    var name: String {
        "\(self.rawValue)_\(Self.default)"
    }
}
