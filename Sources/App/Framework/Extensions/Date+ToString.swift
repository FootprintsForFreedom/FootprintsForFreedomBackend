//
//  Date+ToString.swift
//  
//
//  Created by niklhut on 02.06.22.
//

import Foundation

extension Date {
    /// The accuracy that should be used when converting the date to a string.
    enum Accuracy: Int, CaseIterable {
        /// Don't convert the date to a string.
        case none = 0
        /// Convert year, month and day to a string.
        case day = 1
        /// Convert year, month, day and time to a string.
        case time = 2
        /// Convert year, month, day and time with fractional seconds to a string.
        case exact = 3
        
        /// Get the next more accurate ``Date.Accuracy``.
        /// - Returns: The next more accurate ``Date.Accuracy``.
        func increased() -> Self {
            let allCases = type(of: self).allCases
            return allCases[(allCases.firstIndex(of: self)! + 1) % allCases.count]
        }
    }
    
    /// Converts a `Date` object to a string.
    /// - Parameter accuracy: The ``Date.Accuracy`` that should be used while converting the date to a string.
    /// - Returns: The date with the wanted accuracy as a `String`.
    func toString(with accuracy: Accuracy = .none) -> String {
        let dateFormatter = DateFormatter()
        
        switch accuracy {
        case .none: break
        case .day: dateFormatter.dateFormat = "yyyy-MM-dd"
        case .time: dateFormatter.dateFormat = "yyyy-MM-dd'T'-HH:mm:ss'Z'"
        case .exact: dateFormatter.dateFormat = "yyyy-MM-dd'T'-HH:mm:ss.SSS'Z'"
        }
        
        return dateFormatter.string(from: self)
    }
}
