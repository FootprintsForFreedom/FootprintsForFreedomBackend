//
//  Language+Priority.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Foundation

public extension Language.Language {
//    struct PriorityDetail: Codable {
//        public let id: UUID
//        public let languageCode: String
//        public let name: String
//        public let isRTL: Bool
//        public let priority: Int
//        
//        public init(id: UUID, languageCode: String, name: String, isRTL: Bool, priority: Int) {
//            self.id = id
//            self.languageCode = languageCode
//            self.name = name
//            self.isRTL = isRTL
//            self.priority = priority
//        }
//    }
    
    struct UpdatePriorities: Codable {
        public let newLanguagesOrder: [UUID]
        
        public init(newLanguagesOrder: [UUID]) {
            self.newLanguagesOrder = newLanguagesOrder
        }
    }
}
