//
//  Language+Elastic.swift
//  
//
//  Created by niklhut on 27.09.22.
//

import Foundation
import ISO639

protocol DefaultElasticFilter {
    static var `default`: String { get }
    
    var name: String { get }
}

protocol CustomElasticFilter: DefaultElasticFilter, Equatable {
    var json: [String: Any] { get }
}

//struct CustomElasticFilterJson

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

enum ElasticLowercase: String, CustomElasticFilter {
    case greek
    case irish
    case turkish
    
    var name: String {
        "\(self.rawValue)_\(Self.default)"
    }
    
    static var `default` = "lowercase"
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "language": self.rawValue
            ]
        ]
    }
}

enum ElasticElision: String, CustomElasticFilter {
    case catalan
    case french
    case irish
    case italian
    
    var articles: [String] {
        switch self {
        case .catalan: return ["d", "l", "m", "n", "s", "t"]
        case .french: return ["l", "m", "t", "qu", "n", "s", "j", "d", "c", "jusqu", "quoiqu", "lorsqu", "puisqu"]
        case .irish: return ["d", "m", "b"]
        case .italian: return ["c", "l", "all", "dall", "dell", "nell", "sull", "coll", "pell", "gl", "agl", "dagl", "degl", "negl", "sugl", "un", "m", "t", "s", "v", "d"]
        }
    }
    
    var name: String {
        "\(self.rawValue)_\(Self.default)"
    }
    
    static var `default` = "elision"
    
    var json: [String : Any] {
        [
            name: [
                "type": Self.default,
                "articles": articles,
                "articles_case": true
            ]
        ]
    }
}

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

enum ElasticFilter: Equatable {
    case stop(ElasticStop?)
    case stemmer(ElasticStemmer?)
    case stemmerOverride(ElasticStemmerOverride?)
    case lowercase(ElasticLowercase? = nil)
    case normalization(ElasticNormalization?)
    case elision(ElasticElision?)
    case ngram(ElasticNGram?)
    case wordDelimiterGraph
    case apostrophe
    case cjkWidth
    case cjkBigram
    case decimalDigit
    
    var name: String {
        switch self {
        case .stop(let stop): return stop?.name ?? ElasticStop.default
        case .stemmer(let stemmer): return stemmer?.name ?? ElasticStemmer.default
        case .stemmerOverride(let stemmerOverride): return stemmerOverride?.name ?? ElasticStemmerOverride.default
        case .lowercase(let lowercase): return lowercase?.name ?? ElasticLowercase.default
        case .normalization(let normalization): return normalization?.name ?? ElasticNormalization.default
        case .elision(let elision): return elision?.name ?? ElasticElision.default
        case .ngram(let ngram): return ngram?.name ?? ElasticNGram.default
        case .wordDelimiterGraph: return "word_delimiter_graph"
        case .apostrophe: return "apostrophe"
        case .cjkWidth: return "cjk_width"
        case .cjkBigram: return "cjk_bigram"
        case .decimalDigit: return "decimal_digit"
        }
    }
    
    var customFilter: (any CustomElasticFilter)? {
        switch self {
        case .stop(let stop): return stop
        case .stemmer(let stemmer): return stemmer
        case .stemmerOverride(let stemmerOverride): return stemmerOverride
        case .lowercase(let lowercase): return lowercase
        case .elision(let elision): return elision
        case .ngram(let ngram): return ngram
        default: return nil
        }
    }
}

struct ElasticAnalyzer {
    var filters: [ElasticFilter]
    
    var customFiltersJson: [String: Any] {
        // Map from an array of dictionaries to one dictionary
        let customFilters = filters.compactMap { $0.customFilter?.json }
        let tupleArray = customFilters.flatMap { $0 }
        let dict = Dictionary(tupleArray, uniquingKeysWith: { (first, last) in last })
        return dict
    }
    
    var filterNames: [String] {
        filters.map { $0.name }
    }
    
    var json: [String: Any] {
        [
            "analysis": [
                "filter": customFiltersJson,
                "analyzer": [
                    "default": [
                        "tokenizer": "standard",
                        "filter": filterNames
                    ]
                ]
            ]
        ]
    }
    
    init(_ filters: ElasticFilter...) {
        self.filters = filters
    }
}

extension ISO639.Language {
    /// Analyzers according to the [elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/8.4/analysis-lang-analyzer.html).
    var analyzer: ElasticAnalyzer {
        switch self.alpha1 {
        case .ar: return .init(.lowercase(), .decimalDigit, .stop(.arabic), .normalization(.arabic), .stemmer(.arabic), .wordDelimiterGraph)
        case .hy: return .init(.lowercase(), .stop(.armenian), .stemmer(.armenian), .wordDelimiterGraph)
        case .eu: return .init(.lowercase(), .stop(.basque), .stemmer(.basque), .wordDelimiterGraph)
        case .bn: return .init(.lowercase(), .decimalDigit, .normalization(.indic), .normalization(.bengali), .stop(.bengali), .stemmer(.bengali), .wordDelimiterGraph)
        case .bg: return .init(.lowercase(), .stop(.bulgarian), .stemmer(.bulgarian), .wordDelimiterGraph)
        case .ca: return .init(.elision(.catalan), .lowercase(), .stop(.catalan), .stemmer(.catalan), .wordDelimiterGraph)
        case .zh, .ja, .ko: return .init(.cjkWidth, .lowercase(), .cjkBigram, .stop(.cjk), .wordDelimiterGraph)
        case .cs: return .init(.lowercase(), .stop(.czech), .stemmer(.czech), .wordDelimiterGraph)
        case .da: return .init(.lowercase(), .stop(.danish), .stemmer(.danish), .wordDelimiterGraph)
        case .nl: return .init(.lowercase(), .stop(.dutch), .stemmerOverride(.init(language: "dutch", rules: ["fiets=>fiets", "bromfiets=>bromfiets", "ei=>eier", "kind=>kinder"])), .stemmer(.dutch), .wordDelimiterGraph)
        case .en: return .init(.stemmer(.englishPossessive), .lowercase(), .stop(.english), .stemmer(.english), .wordDelimiterGraph)
        case .et: return .init(.lowercase(), .stop(.estonian), .stemmer(.estonian), .wordDelimiterGraph)
        case .fi: return .init(.lowercase(), .stop(.finnish), .stemmer(.finnish), .wordDelimiterGraph)
        case .fr: return .init(.elision(.french), .lowercase(), .stop(.french), .stemmer(.french), .wordDelimiterGraph)
        case .gl: return .init(.lowercase(), .stop(.galician), .stemmer(.galician), .wordDelimiterGraph)
        case .de: return .init(.lowercase(), .stop(.german), .normalization(.german), .stemmer(.german), .wordDelimiterGraph, .ngram(.trigram))
        case .el: return .init(.lowercase(.greek), .stop(.greek), .stemmer(.greek), .wordDelimiterGraph)
        case .hi: return .init(.lowercase(), .decimalDigit, .normalization(.indic), .normalization(.hindi), .stop(.hindi), .stemmer(.hindi), .wordDelimiterGraph)
        case .hu: return .init(.lowercase(), .stop(.hungarian), .stemmer(.hungarian), .wordDelimiterGraph)
        case .id: return .init(.lowercase(), .stop(.indonesian), .stemmer(.indonesian), .wordDelimiterGraph)
        case .ga: return .init(.stop(.custom(name: "irish_hyphenation", stopwords: ["h", "n", "t"])), .elision(.irish), .lowercase(.irish), .stop(.irish), .stemmer(.irish), .wordDelimiterGraph)
        case .it: return .init(.elision(.italian), .lowercase(), .stop(.italian), .stemmer(.italian), .wordDelimiterGraph)
        case .lv: return .init(.lowercase(), .stop(.latvian), .stemmer(.latvian), .wordDelimiterGraph)
        case .lt: return .init(.lowercase(), .stop(.lithuanian), .stemmer(.lithuanian), .wordDelimiterGraph)
        case .no: return .init(.lowercase(), .stop(.norwegian), .stemmer(.norwegian), .wordDelimiterGraph)
        case .fa: return .init(.lowercase(), .decimalDigit, .normalization(.arabic), .normalization(.persian), .stop(.persian), .wordDelimiterGraph) // Zero_width_spaces
        case .pt: return .init(.lowercase(), .stop(.portuguese), .stemmer(.portuguese), .wordDelimiterGraph)
        case .ro: return .init(.lowercase(), .stop(.romanian), .stemmer(.romanian), .wordDelimiterGraph)
        case .ru: return .init(.lowercase(), .stop(.russian), .stemmer(.russian), .wordDelimiterGraph)
        case .es: return .init(.lowercase(), .stop(.spanish), .stemmer(.spanish), .wordDelimiterGraph)
        case .sv: return .init(.lowercase(), .stop(.swedish), .stemmer(.swedish), .wordDelimiterGraph)
        case .tr: return .init(.apostrophe, .lowercase(.turkish), .stop(.turkish), .stemmer(.turkish), .wordDelimiterGraph)
        case .th: return .init(.lowercase(), .decimalDigit, .stop(.thai), .wordDelimiterGraph)
        default: return .init()
        }
    }
}
