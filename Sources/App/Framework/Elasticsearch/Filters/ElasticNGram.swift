//
//  ElasticNGram.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

struct ElasticNGram: CustomElasticFilter {
    static var `default` = "ngram"
    
    var name: String
    var minGram: Int
    var maxGram: Int
    // note that empty array keeps all
    var tokenChars: [TokenChars]
    // note that .custom token chars must be set to use this
    var customTokenChars: [Character]
    
    enum TokenChars: String {
        case letter
        case digit
        case whitespace
        case punctuation
        case symbol
        case custom
    }
    
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
