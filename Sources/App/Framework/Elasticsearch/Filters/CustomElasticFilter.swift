//
//  CustomElasticFilter.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

protocol CustomElasticFilter: DefaultElasticFilter, Equatable {
    var json: [String: Any] { get }
}
