//
//  Array+Grouped.swift
//  
//
//  Created by niklhut on 04.06.22.
//

import Foundation

extension Array  {
    func grouped<Key: Hashable>(by keyForValue: (Element) throws -> Key) throws -> Dictionary<Key, [Element]> {
        return try Dictionary(grouping: self, by: keyForValue)
    }
}
