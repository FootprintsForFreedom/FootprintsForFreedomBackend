//
//  Language+Priority.swift
//  
//
//  Created by niklhut on 08.03.22.
//

import Foundation

public extension Language.Detail {
    /// Used to detail language objects.
    struct UpdatePriorities: Codable {
        /// An array containing all active language ids in the new order they should be arranged. The first item will have the highest priority.
        public let newLanguagesOrder: [UUID]
        
        /// Create a language update priorities object.
        /// - Parameter newLanguagesOrder: An array containing all active language ids in the new order they should be arranged. The first item will have the highest priority.
        public init(newLanguagesOrder: [UUID]) {
            self.newLanguagesOrder = newLanguagesOrder
        }
    }
}
