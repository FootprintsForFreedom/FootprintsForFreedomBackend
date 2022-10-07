//
//  ElasticStemmer.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Provides [algorithmic stemming](https://www.elastic.co/guide/en/elasticsearch/reference/current/stemming.html#algorithmic-stemmers) for several languages, some with additional variants.
enum ElasticStemmer: String, CustomElasticFilter {
    case arabic
    case armenian
    case basque
    case bengali
    case brazilian
    case bulgarian
    case catalan
    case czech
    case danish
    case dutch
    case dutchKp = "dutch_kp"
    case english
    case lightEnglish = "light_english"
    case lovins
    case minimalEnglish = "minimal_english"
    case porter2
    case possessiveEnglish = "possessive_english"
    case estonian
    case finnish
    case lightFinnish = "light_finnish"
    case lightFrench = "light_french"
    case french
    case minimalFrench = "minimal_french"
    case galician
    case minimalGalician = "minimal_galician"
    case lightGerman = "light_german"
    case german
    case german2
    case minimalGerman = "minimal_german"
    case greek
    case hindi
    case hungarian
    case lightHungarian = "light_hungarian"
    case indonesian
    case irish
    case lightItalian = "light_italian"
    case italian
    case sorani
    case latvian
    case lithuanian
    case norwegian
    case lightNorwegian = "light_norwegian"
    case minimalNorwegian = "minimal_norwegian"
    case lightNynorsk = "light_nynorsk"
    case minimalNynorsk = "minimal_nynorsk"
    case lightPortuguese = "light_portuguese"
    case minimalPortuguese = "minimal_portuguese"
    case portuguese
    case portugueseRSLP = "portuguese_rslp"
    case romanian
    case russian
    case lightRussian = "light_russian"
    case lightSpanish = "light_spanish"
    case spanish
    case lightSwedish = "light_swedish"
    case swedish
    case turkish
    
    var name: String {
        "\(self.rawValue)_\(Self.default)"
    }
    
    static var `default` = "stemmer"
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "language": self.rawValue
            ]
        ]
    }
}
