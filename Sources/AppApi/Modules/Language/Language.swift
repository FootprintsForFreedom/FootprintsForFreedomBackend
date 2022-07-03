//
//  Language.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Foundation

public enum Language: ApiModuleInterface { }

public extension Language {
    enum Language: ApiModelInterface {
        public typealias Module = AppApi.Language
    }
}

public extension Language.Language {
    /// Used to list language objects.
    struct List: Codable {
        /// Id uniquely identifying the language.
        public let id: UUID
        /// A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        /// The language's unique name.
        public let name: String
        /// A boolean value indicating wether or not the language is right-to-left or not.
        public let isRTL: Bool
        
        /// Create a language list object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the language.
        ///   - languageCode: A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        ///   - name: The language's unique name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(id: UUID, languageCode: String, name: String, isRTL: Bool) {
            self.id = id
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    /// Used to detail language objects.
    struct Detail: Codable {
        /// Id uniquely identifying the language.
        public let id: UUID
        /// A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        /// The language's unique name.
        public let name: String
        /// A boolean value indicating wether or not the language is right-to-left or not.
        public let isRTL: Bool
        
        /// Create a language detail object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the language.
        ///   - languageCode: A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        ///   - name: The language's unique name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(id: UUID, languageCode: String, name: String, isRTL: Bool) {
            self.id = id
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    /// Used to create language objects.
    struct Create: Codable {
        /// A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        /// The language's unique name.
        public let name: String
        /// A boolean value indicating wether or not the language is right-to-left or not.
        public let isRTL: Bool
        
        /// Create a language create object.
        /// - Parameters:
        ///   - languageCode: A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        ///   - name: The language's unique name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(languageCode: String, name: String, isRTL: Bool) {
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    /// Used to update language objects.
    struct Update: Codable {
        /// A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        /// The language's unique name.
        public let name: String
        /// A boolean value indicating wether or not the language is right-to-left or not.
        public let isRTL: Bool
        
        /// Create a language update object.
        /// - Parameters:
        ///   - languageCode: A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format
        ///   - name: The language's unique name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(languageCode: String, name: String, isRTL: Bool) {
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    /// Used to patch language objects.
    struct Patch: Codable {
        /// A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String?
        /// The language's unique name.
        public let name: String?
        /// A boolean value indicating wether or not the language is right-to-left or not.
        public let isRTL: Bool?
        
        /// Create a language patch object.
        /// - Parameters:
        ///   - languageCode: A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format
        ///   - name: The language's unique name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(languageCode: String?, name: String?, isRTL: Bool?) {
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
}
