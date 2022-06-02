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
        case month = 1
        case day = 2
        case hour = 3
        case minute = 4
        case second = 5
        case exact = 6
        
        func increased() -> Self {
            let allCases = type(of: self).allCases
            return allCases[(allCases.firstIndex(of: self)! + 1) % allCases.count]
        }
    }
    
    func toString(with accuracy: Accuracy = .none) -> String {
        let dateFormatter = DateFormatter()
        
        switch accuracy {
        case .none: break
        case .month: dateFormatter.dateFormat = "yyyy-MM"
        case .day: dateFormatter.dateFormat = "yyyy-MM-dd"
        case .hour: dateFormatter.dateFormat = "yyyy-MM-dd-HH"
        case .minute: dateFormatter.dateFormat = "yyyy-MM-dd-HH.mm"
        case .second: dateFormatter.dateFormat = "yyyy-MM-dd-HH.mm.ss"
        case .exact: dateFormatter.dateFormat = "yyyy-MM-dd-HH.mm.ss.SSS"
        }
        
        return dateFormatter.string(from: Date())

    }
}
