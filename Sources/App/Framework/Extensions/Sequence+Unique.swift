//
//  Sequence+Unique.swift
//  
//
//  Created by niklhut on 03.03.22.
//

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
