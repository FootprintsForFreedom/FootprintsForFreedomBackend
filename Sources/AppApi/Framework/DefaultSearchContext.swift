//
//  DefaultSearchContext.swift
//  
//
//  Created by niklhut on 31.01.23.
//

import Foundation

/// Default search context used when performing a search request.
public struct DefaultSearchContext: Codable {
    /// The text for which to search.
    public let text: String
    /// The language code of the language to be searched.
    public let languageCode: String
    
    /// Creates a default serach context.
    /// - Parameters:
    ///   - text: The text for which to search.
    ///   - languageCode: The language code of the language to be searched.
    public init(text: String, languageCode: String) {
        self.text = text
        self.languageCode = languageCode
    }
}
