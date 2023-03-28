//
//  ElasticAnalyzer.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Represents an elasticsearch analyzer.
struct ElasticAnalyzer {
    /// List of the filters used for this analyzer.
    var filters: [ElasticFilter]
    
    /// The json representation of all custom filters.
    var customFiltersJson: [String: Any] {
        // Map from an array of dictionaries to one dictionary
        let customFilters = filters.compactMap { $0.customFilter?.json }
        let tupleArray = customFilters.flatMap { $0 }
        let dict = Dictionary(tupleArray, uniquingKeysWith: { (first, last) in last })
        return dict
    }
    
    /// The names of the used filters.
    var filterNames: [String] {
        filters.map { $0.name }
    }
    
    /// The json representation of the analyzer.
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
    
    /// Creates an elasticsearch analyzer with the specified filters.
    /// - Parameter filters: The filters to be used for the analyzer.
    init(_ filters: ElasticFilter...) {
        self.filters = filters
    }
}
