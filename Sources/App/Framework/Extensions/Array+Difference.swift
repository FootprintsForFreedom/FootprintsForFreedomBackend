//
//  Array+Difference.swift
//  
//
//  Created by niklhut on 27.05.22.
//

import Foundation

extension Array where Element: Equatable {
    /// Computes the difference between this array and another array of the same type.
    /// - Parameter other: The secondary array which will be used to compute the difference.
    /// - Returns: A tuple with the elements which remained equal in both arrays, the elements which were added to the array calling this funciton and the elements which were removed from the array calling the function but are present in the other one.
    func difference(from other: [Element]) -> (equal: [Element], deleted: [Element], inserted: [Element]) {
        let combinations = self.map { firstElement in (firstElement, other.first { $0 == firstElement })}
        let equal = combinations.filter { $0.1 != nil }.map { ($0.0) }
        let deleted = combinations.filter { $0.1 == nil }.map { ($0.0) }
        let inserted = other.filter { secondElement in !equal.contains { $0 == secondElement } }
        
        return (equal, deleted, inserted)
    }
}
