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
    struct List: Codable {
        public let id: UUID
        public let languageCode: String
        public let name: String
        public let isRTL: Bool
        
        public init(id: UUID, languageCode: String, name: String, isRTL: Bool) {
            self.id = id
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let languageCode: String
        public let name: String
        public let isRTL: Bool
        
        public init(id: UUID, languageCode: String, name: String, isRTL: Bool) {
            self.id = id
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    struct Create: Codable {
        public let languageCode: String
        public let name: String
        public let isRTL: Bool
        
        public init(languageCode: String, name: String, isRTL: Bool) {
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    struct Update: Codable {
        public let languageCode: String
        public let name: String
        public let isRTL: Bool
        
        public init(languageCode: String, name: String, isRTL: Bool) {
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
    
    struct Patch: Codable {
        public let languageCode: String?
        public let name: String?
        public let isRTL: Bool?
        
        public init(languageCode: String?, name: String?, isRTL: Bool?) {
            self.languageCode = languageCode
            self.name = name
            self.isRTL = isRTL
        }
    }
}
