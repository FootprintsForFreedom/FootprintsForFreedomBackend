//
//  Titled.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Fluent

/// Represents a model with a title
protocol Titled where Self: Fluent.Model {
    /// The model's title.
    var title: String { get set }
}
