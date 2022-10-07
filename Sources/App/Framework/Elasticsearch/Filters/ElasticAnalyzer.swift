//
//  ElasticAnalyzer.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

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
