//
//  ElasticElision.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Removes specified elisions from the beginning of tokens.
///
/// For example, you can use this filter to change `l'avion` to `avion`.
///
/// When not customized, the filter removes the following French elisions by default:
/// `l'`, `m'`, `t'`, `qu'`, `n'`, `s'`, `j'`, `d'`, `c'`, `jusqu'`, `quoiqu'`, `lorsqu'`, `puisqu'`
struct ElasticElision: CustomElasticFilter {
    static var `default` = "elision"
    var name: String
    
    /// List of elisions to remove.
    ///
    /// To be removed, the elision must be at the beginning of a token and be immediately followed by an apostrophe. Both the elision and apostrophe are removed.
    var articles: [String]
    
    /// If true, elision matching is case insensitive. If false, elision matching is case sensitive. Defaults to false.
    var articlesCase: Bool = true
    
    init(name: String, articles: [String], articlesCase: Bool = true) {
        self.name = name
        self.articles = articles
        self.articlesCase = articlesCase
    }
    
    init(namePrefix: String, articles: [String], articlesCase: Bool = true) {
        self.name = "\(namePrefix)_\(Self.default)"
        self.articles = articles
        self.articlesCase = articlesCase
    }
    
    var json: [String : Any] {
        [
            name: [
                "type": Self.default,
                "articles": articles,
                "articles_case": articlesCase
            ]
        ]
    }
}

extension ElasticElision {
    /// Customized elision filter for catalan.
    static var catalan: Self {
        .init(namePrefix: "catalan", articles: ["d", "l", "m", "n", "s", "t"])
    }
    
    /// Customized elision filter for french.
    static var french: Self {
        .init(namePrefix: "french", articles: ["l", "m", "t", "qu", "n", "s", "j", "d", "c", "jusqu", "quoiqu", "lorsqu", "puisqu"])
    }
    
    /// Customized elision filter for irish.
    static var irish: Self {
        .init(namePrefix: "irish", articles: ["d", "m", "b"])
    }
    
    /// Customized elision filter for italian.
    static var italian: Self {
        .init(namePrefix: "italian", articles: ["c", "l", "all", "dall", "dell", "nell", "sull", "coll", "pell", "gl", "agl", "dagl", "degl", "negl", "sugl", "un", "m", "t", "s", "v", "d"])
    }
}
