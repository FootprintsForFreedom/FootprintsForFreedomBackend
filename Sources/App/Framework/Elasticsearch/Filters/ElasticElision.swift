//
//  ElasticElision.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

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
