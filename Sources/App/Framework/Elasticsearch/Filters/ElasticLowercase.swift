//
//  ElasticLowercase.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Changes token text to lowercase.
///
/// For example, you can use the lowercase filter to change `THE Lazy DoG` to `the lazy dog`.
enum ElasticLowercase: String, CustomElasticFilter {
    case greek
    case irish
    case turkish
    
    static var `default` = "lowercase"
    var name: String { "\(language)_\(Self.default)" }
    
    /// Language-specific lowercase token filter to use.
    ///
    /// Valid values include: `greek`, `irish`, `turkish`.
    var language: String { self.rawValue }
    
    var json: [String: Any] {
        [
            name: [
                "type": Self.default,
                "language": language
            ]
        ]
    }
}

