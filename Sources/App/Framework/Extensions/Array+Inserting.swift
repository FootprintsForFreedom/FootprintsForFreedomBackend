//
//  Array+Inserting.swift
//  
//
//  Created by niklhut on 03.03.22.
//

extension Array {
    /// Inserts a new element into an array at a specified position without modifying the array itself.
    ///
    /// The new element is inserted before the element currently at the specified index. If you pass the array’s endIndex property as the index parameter, the new element is appended to the array
    ///
    /// - Complexity: O(n), where n is the length of the array. If i == endIndex, this method is equivalent to append(_:).
    ///
    /// - Parameters:
    ///   - newElement: The new element to insert into the array.
    ///   - index: The position at which to insert the new element. index must be a valid index of the array or equal to its endIndex property.
    /// - Returns: The changed array
    func inserting(_ newElement: Element, at index: Int) -> [Element] {
        var arrray = self
        arrray.insert(newElement, at: index)
        return arrray
    }
    
    /// Inserts a new element into an array at a specified position without modifying the array itself.
    ///
    /// The new element is inserted before the element currently at the specified index. If you pass the array’s endIndex property as the index parameter, the new element is appended to the array
    ///
    /// - Complexity: O(n), where n is the length of the array. If i == endIndex, this method is equivalent to append(_:).
    ///
    /// - Parameters:
    ///   - newElement: The new element to insert into the array.
    ///   - index: The position at which to insert the new element. index must be a valid index of the array or equal to its endIndex property.
    /// - Returns: The changed array
    func inserting(_ newElement: Element?, at index: Int) -> [Element] {
        if let newElement = newElement {
            return self.inserting(newElement, at: index)
        } else {
            return self
        }
    }
}
