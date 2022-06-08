//
//  Titled.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Fluent

protocol Titled: Fluent.Model {
    var title: String { get set }
}
