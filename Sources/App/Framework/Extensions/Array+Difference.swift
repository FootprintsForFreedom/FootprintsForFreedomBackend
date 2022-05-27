//
//  File.swift
//  
//
//  Created by niklhut on 27.05.22.
//

import Foundation

extension Array where Element: Equatable {
    func difference(from other: [Element]) -> (equal: [Element], deleted: [Element], inserted: [Element]) {
        let combinations = self.map { firstElement in (firstElement, other.first { $0 == firstElement })}
        let equal = combinations.filter { $0.1 != nil }.map { ($0.0) }
        let deleted = combinations.filter { $0.1 == nil }.map { ($0.0) }
        let inserted = other.filter { secondElement in !equal.contains { $0 == secondElement } }
        
        return (equal, deleted, inserted)
    }
}
