//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public struct ValidationErrorDetail: Codable {

    public var key: String
    public var message: String
    
    public init(key: String, message: String) {
        self.key = key
        self.message = message
    }
}

extension ValidationErrorDetail: Content {}
