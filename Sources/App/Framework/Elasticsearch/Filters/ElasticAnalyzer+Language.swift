//
//  ElasticAnalyzer+Language.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation
import ISO639

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
