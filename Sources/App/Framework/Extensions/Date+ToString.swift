//
//  Date+ToString.swift
//  
//
//  Created by niklhut on 02.06.22.
//

import Foundation

extension Date {
    enum Accuracy: Int, CaseIterable {
        case none = 0
        case year = 1
        case month = 2
        case day = 3
        case time = 4
        case exact = 5
        
        func increased() -> Self {
            let allCases = type(of: self).allCases
            return allCases[(allCases.firstIndex(of: self)! + 1) % allCases.count]
        }
    }
    
    func toString(with accuracy: Accuracy = .none) -> String {
        let dateFormatter = DateFormatter()
        
        switch accuracy {
        case .none: break
        case .year: dateFormatter.dateFormat = "yyyy"
        case .month: dateFormatter.dateFormat = "yyyy-MM"
        case .day: dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        case .time: dateFormatter.dateFormat = "yyyy-MM-dd'T'-HH:mm:ss'Z'"
        case .exact: dateFormatter.dateFormat = "yyyy-MM-dd'T'-HH:mm:ss.SSS'Z'"
        }
        
        return dateFormatter.string(from: self)
    }
}
