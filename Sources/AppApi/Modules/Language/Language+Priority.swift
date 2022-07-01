//
//  Language+Priority.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Foundation

public extension Language.Language {
    struct UpdatePriorities: Codable {
        public let newLanguagesOrder: [UUID]
        
        public init(newLanguagesOrder: [UUID]) {
            self.newLanguagesOrder = newLanguagesOrder
        }
    }
}
