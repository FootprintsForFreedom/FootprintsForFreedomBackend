//
//  ElasticStemmerOverride.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Overrides stemming algorithms, by applying a custom mapping, then protecting these terms from being modified by stemmers.
///
/// Must be placed before any stemming filters.
struct ElasticStemmerOverride: CustomElasticFilter {
    static var `default` = "stemmer_override"
    var name: String
    
    /// A list of mapping rules to use.
    ///
    /// Rules are mappings in the form of `token1[, ..., tokenN] => override.
    var rules: [String]
    
    /// Creates a elastic stemmer override filter with the given parameters.
    ///
    /// Rules are mappings in the form of `token1[, ..., tokenN] => override.
    ///
    /// - Parameters:
    ///   - namePrefix: The part of the name prefixed before the default name.
    ///   - rules: A list of mapping rules to use.
    init(namePrefix: String, rules: [String]) {
        self.name = "\(namePrefix)_\(Self.default)"
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
