//
//  Array+Inserting.swift
//  
//
//  Created by niklhut on 03.03.22.
//

extension Array {
    func inserting(_ newElement: Element, at index: Int) -> [Element] {
        var arrray = self
        arrray.insert(newElement, at: index)
        return arrray
    }
    
    func inserting(_ newElement: Element?, at index: Int) -> [Element] {
        if let newElement = newElement {
            return self.inserting(newElement, at: index)
        } else {
            return self
        }
    }
}
