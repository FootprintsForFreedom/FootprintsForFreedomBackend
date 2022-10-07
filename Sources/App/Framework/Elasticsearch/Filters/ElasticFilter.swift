//
//  ElasticFilter.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Represents an elasticsearch filter.
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
    
    /// The filter's name.
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
    
    /// The filter's json representation if it is not a default filter.
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
