//
//  DefaultElasticFilter.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Foundation

protocol DefaultElasticFilter {
    static var `default`: String { get }
    
    var name: String { get }
}
