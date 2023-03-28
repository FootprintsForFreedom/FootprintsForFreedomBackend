//
//  LanguageRequest.swift
//  
//
//  Created by niklhut on 31.01.23.
//

import Foundation

public extension Language {
    /// Contains the data transfer objects to request  languages.
    enum Request: ApiModelInterface {
        public typealias Module = AppApi.Language
    }
}

public extension Language.Request {
    /// Used to send the preferred language with a request.
    struct PreferredLanguage: Codable {
        /// The preferred language for which results should ideally be returned.
        public let preferredLanguage: String?
        
        /// Creates a preferred language object.
        /// - Parameter preferredLanguage: The preferred language for which results should ideally be returned.
        public init(preferredLanguage: String?) {
            self.preferredLanguage = preferredLanguage
        }
    }
}
