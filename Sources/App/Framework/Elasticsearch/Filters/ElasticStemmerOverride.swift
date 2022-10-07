//
//  ElasticStemmerOverride.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

struct ElasticStemmerOverride: CustomElasticFilter {
    static var `default` = "stemmer_override"
    
    var name: String
    var rules: [String]
    
    init(language: String, rules: [String]) {
        self.name = "\(language)_\(Self.default)"
        self.rules = rules
    }
    
    var json: [String : Any] {
        [
            name: [
                "type": Self.default,
                "rules": rules
            ]
        ]
    }
}
