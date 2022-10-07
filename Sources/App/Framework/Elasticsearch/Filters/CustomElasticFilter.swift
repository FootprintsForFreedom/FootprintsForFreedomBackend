//
//  CustomElasticFilter.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

/// Represents a custom elasticsearch filter.
protocol CustomElasticFilter: DefaultElasticFilter, Equatable {
    /// The json representation of the filter.
    var json: [String: Any] { get }
}
