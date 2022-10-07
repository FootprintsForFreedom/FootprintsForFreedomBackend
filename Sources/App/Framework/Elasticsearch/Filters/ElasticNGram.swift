//
//  ElasticNGram.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// The ngram tokenizer first breaks text down into words whenever it encounters one of a list of specified characters, then it emits N-grams of each word of the specified length.
///
/// N-grams are like a sliding window that moves across the word - a continuous sequence of characters of the specified length. They are useful for querying languages that don’t use spaces or that have long compound words, like German.
struct ElasticNGram: CustomElasticFilter {
    static var `default` = "ngram"
    var name: String
    
    /// Minimum length of characters in a gram
    var minGram: Int
    
    /// Maximum length of characters in a gram.
    var maxGram: Int
    
    /// Character classes that should be included in a token. Elasticsearch will split on characters that don’t belong to the classes specified.
    ///
    /// An empty array indicates to keep all characters.
    var tokenChars: [TokenChars]
    
    /// Custom characters that should be treated as part of a token.
    ///
    /// For example, setting this to `+-_` will make the tokenizer treat the plus, minus and underscore sign as part of a token.
    ///
    /// - Note: To use the custom token characters `tokenChars` needs to contain `.custom`.
    var customTokenChars: [Character]
    
    /// Available character classes that can be included in a token.
    enum TokenChars: String {
        /// Letters – for example `a`, `b`, `ï` or `京`
        case letter
        /// Digits – for example `3` or `7`
        case digit
        /// Whitespaces – for example `" "` or `"\n"`
        case whitespace
        /// Punctuation – for example `!` `or "`
        case punctuation
        /// Symbols – for example `$` or `√`
        case symbol
        /// Custom characters which need to be set using the `custom_token_chars` setting.
        case custom
    }
    
    /// Creates an elastic n-gram with the specified parameters.
    ///
    /// To use the custom token characters `tokenChars` needs to contain `.custom`.
    ///
    /// - Parameters:
    ///   - name: The filter’s name.
    ///   - minGram: Minimum length of characters in a gram
    ///   - maxGram: Maximum length of characters in a gram.
    ///   - tokenChars: Character classes that should be included in a token. Elasticsearch will split on characters that don’t belong to the classes specified. An empty array indicates to keep all characters.
    ///   - customTokenChars: Custom characters that should be treated as part of a token.
    init(name: String, minGram: Int, maxGram: Int, tokenChars: [TokenChars], customTokenChars: [Character]? = nil) {
        self.name = name
        self.minGram = minGram
        self.maxGram = maxGram
        self.tokenChars = tokenChars
        self.customTokenChars = customTokenChars ?? []
    }
    
    var json: [String : Any] {
        [
            name: [
                "type": Self.default,
                "min_gram": minGram,
                "max_gram": maxGram,
                "token_chars": tokenChars.map { $0.rawValue },
                "custom_token_chars": customTokenChars
            ]
        ]
    }
}

extension ElasticNGram {
    static var trigram: Self {
        .init(name: "trigram", minGram: 3, maxGram: 3, tokenChars: [.letter, .digit])
    }
}
