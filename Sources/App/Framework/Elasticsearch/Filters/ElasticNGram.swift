//
//  ElasticNGram.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Forms n-grams of specified lengths from a token.
///
/// For example, you can use the ngram token filter to change `fox` to `[ f, fo, o, ox, x ]`.
struct ElasticNGram: CustomElasticFilter {
    static var `default` = "ngram"
    var name: String
    
    /// Minimum length of characters in a gram
    var minGram: Int
    
    /// Maximum length of characters in a gram.
    var maxGram: Int
    
    /// Emits original token when set to `true`.
    var preserveOriginal: Bool = false
    
    /// Creates an elastic n-gram with the specified parameters.
    /// - Parameters:
    ///   - name: The filter's name.
    ///   - minGram: Minimum length of characters in a gram.
    ///   - maxGram: Maximum length of characters in a gram.
    ///   - preserveOriginal: Wether or not to emit the original token.
    init(name: String, minGram: Int, maxGram: Int, preserveOriginal: Bool = false) {
        self.name = name
        self.minGram = minGram
        self.maxGram = maxGram
        self.preserveOriginal = preserveOriginal
    }
    
    var json: [String : Any] {
        [
            name: [
                "type": Self.default,
                "min_gram": minGram,
                "max_gram": maxGram,
                "preserve_original": preserveOriginal
            ]
        ]
    }
}

extension ElasticNGram {
    static var trigram: Self {
        .init(name: "trigram", minGram: 3, maxGram: 3, preserveOriginal: true)
    }
}
