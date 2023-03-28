//
//  LanguageDetail.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Foundation

public extension Language {
    /// Contains the language detail data transfer objects.
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Language
    }
}

public extension Language.Detail {
    /// Used to list languages not yet added to the system.
    struct ListUnused: Codable {
        /// A unique language code identifying the language. In the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        /// The language's unique name in english.
        public let name: String
        /// The language's official name.
        public let officialName: String
        
        /// Creates a language list unused object.
        /// - Parameters:
        ///   - languageCode: A unique language code identifying the language. In the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        ///   - name: The language's unique name.
        ///   - officialName: The language's official name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(languageCode: String, name: String, officialName: String) {
            self.languageCode = languageCode
            self.name = name
            self.officialName = officialName
        }
    }
    
    /// Used to list language objects.
    typealias List = Detail
    
    /// Used to detail language objects.
    struct Detail: Codable {
        /// Id uniquely identifying the language.
        public let id: UUID
        /// A unique language code identifying the language. In the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        /// The language's unique name in english.
        public let name: String
        /// The language's official name.
        public let officialName: String
        /// A boolean value indicating wether or not the language is right-to-left or not.
        public let isRTL: Bool
        
        /// Creates a language detail object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the language.
        ///   - languageCode: A unique language code identifying the language. In the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        ///   - name: The language's unique name.
        ///   - officialName: The language's official name.
        ///   - isRTL: A boolean value indicating wether or not the language is right-to-left or not.
        public init(id: UUID, languageCode: String, name: String, officialName: String, isRTL: Bool) {
            self.id = id
            self.languageCode = languageCode
            self.name = name
            self.officialName = officialName
            self.isRTL = isRTL
        }
    }
    
    /// Used to create language objects.
    struct Create: Codable {
        /// A unique language code identifying the language. Must be in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public let languageCode: String
        
        /// Creates a language create object.
        /// - Parameters:
        ///   - languageCode: A unique language code identifying the language. Must be in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
        public init(languageCode: String) {
            self.languageCode = languageCode
        }
    }
    
    /// Used to update the priority order of all active languages.
    struct UpdatePriorities: Codable {
        /// An array containing all active language ids in the new order they should be arranged. The first item will have the highest priority.
        public let newLanguagesOrder: [UUID]
        
        /// Creates a language update priorities object.
        /// - Parameter newLanguagesOrder: An array containing all active language ids in the new order they should be arranged. The first item will have the highest priority.
        public init(newLanguagesOrder: [UUID]) {
            self.newLanguagesOrder = newLanguagesOrder
        }
    }
}
