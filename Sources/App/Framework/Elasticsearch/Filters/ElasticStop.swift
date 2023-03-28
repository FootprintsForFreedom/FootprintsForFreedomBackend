//
//  ElasticStop.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Removes [stop words](https://en.wikipedia.org/wiki/Stop_words) from a token stream.
struct ElasticStop: CustomElasticFilter {
    static var `default` = "stop"
    var name: String
    
    /// Language value, such as `_arabic_` or `_thai_`. Defaults to _english_.
    ///
    /// Each language value corresponds to a predefined list of stop words in Lucene. See Stop words by language for supported language values and their stop words.
    var language: String?
    
    /// An array of stop words.
    var stopwords: [String]?
    
    /// If `true`, stop word matching is case insensitive.
    ///
    /// For example, if true, a stop word of `the` matches and removes `The`, `THE`, or `the`. Defaults to `false`.
    var ignoreCase = false
    
    /// If `true`, the last token of a stream is removed if it’s a stop word. Defaults to `true`.
    ///
    /// This parameter should be `false` when using the filter with a completion suggester. This would ensure a query like `green a` matches and suggests `green apple` while still removing other stop words.
    var removeTrailing = true
    
    /// Creates a stop filter with custom stopwords
    /// - Parameters:
    ///   - namePrefix: The part of the name prefixed before the default name.
    ///   - stopwords: An array of stopwords
    ///   - ignoreCase: Wether or not the word matching is case insensitive.
    ///   - removeTrailing: Wether or not the last token of a steam should be removed.
    init(namePrefix: String, stopwords: [String], ignoreCase: Bool = false, removeTrailing: Bool = true) {
        self.name = "\(namePrefix)_\(Self.default)"
        self.language = nil
        self.stopwords = stopwords
        self.ignoreCase = ignoreCase
        self.removeTrailing = removeTrailing
    }
    
    /// Creates a stop filter for a specified language.
    /// - Parameters:
    ///   - language: The language to be used.
    ///   - ignoreCase: Wether or not the word matching is case insensitive.
    ///   - removeTrailing: Wether or not the last token of a steam should be removed.
    private init(language: String, ignoreCase: Bool = false, removeTrailing: Bool = false) {
        self.name = "\(language)_\(Self.default)"
        self.stopwords = nil
        self.ignoreCase = ignoreCase
        self.removeTrailing = removeTrailing
    }
    
    var stopwordsValue: Any {
        if let language {
            return language
        } else if let stopwords {
            return stopwords
        } else {
            return ""
        }
    }
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "stopwords": stopwordsValue,
                "ignore_case": ignoreCase,
                "remove_trailing": removeTrailing
            ] 
        ]
    }
}

extension ElasticStop {
    static var arabic: Self {
        .init(language: "arabic")
    }
    
    static var armenian: Self {
        .init(language: "armenian")
    }
    
    static var basque: Self {
        .init(language: "basque")
    }
    
    static var bengali: Self {
        .init(language: "bengali")
    }
    
    static var brazilian: Self {
        .init(language: "brazilian")
    }
    
    static var bulgarian: Self {
        .init(language: "bulgarian")
    }
    
    static var catalan: Self {
        .init(language: "catalan")
    }
    
    static var cjk: Self {
        .init(language: "cjk")
    }
    
    static var czech: Self {
        .init(language: "czech")
    }
    
    static var danish: Self {
        .init(language: "danish")
    }
    
    static var dutch: Self {
        .init(language: "dutch")
    }
    
    static var english: Self {
        .init(language: "english")
    }
    
    static var estonian: Self {
        .init(language: "estonian")
    }
    
    static var finnish: Self {
        .init(language: "finnish")
    }
    
    static var french: Self {
        .init(language: "french")
    }
    
    static var galician: Self {
        .init(language: "galician")
    }
    
    static var german: Self {
        .init(language: "german")
    }
    
    static var greek: Self {
        .init(language: "greek")
    }
    
    static var hindi: Self {
        .init(language: "hindi")
    }
    
    static var hungarian: Self {
        .init(language: "hungarian")
    }
    
    static var indonesian: Self {
        .init(language: "indonesian")
    }
    
    static var irish: Self {
        .init(language: "irish")
    }
    
    static var italian: Self {
        .init(language: "italian")
    }
    
    static var latvian: Self {
        .init(language: "latvian")
    }
    
    static var lithuanian: Self {
        .init(language: "lithuanian")
    }
    
    static var norwegian: Self {
        .init(language: "norwegian")
    }
    
    static var persian: Self {
        .init(language: "persian")
    }
    
    static var portuguese: Self {
        .init(language: "portuguese")
    }
    
    static var romanian: Self {
        .init(language: "romanian")
    }
    
    static var russian: Self {
        .init(language: "russian")
    }
    
    static var sorani: Self {
        .init(language: "sorani")
    }
    
    static var spanish: Self {
        .init(language: "spanish")
    }
    
    static var swedish: Self {
        .init(language: "swedish")
    }
    
    static var thai: Self {
        .init(language: "thai")
    }
    
    static var turkish: Self {
        .init(language: "turkish")
    }
}
