//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Foundation

public struct Name {
   
    let singular: String
    let plural: String
    
    internal init(singular: String, plural: String? = nil) {
        self.singular = singular
        self.plural = plural ?? singular + "s"
    }
}
