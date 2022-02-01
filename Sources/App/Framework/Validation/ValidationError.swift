//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

struct ValidationError: Codable {

    let message: String?
    let details: [ValidationErrorDetail]
    
    init(message: String?, details: [ValidationErrorDetail]) {
        self.message = message
        self.details = details
    }
}

extension ValidationError: Content {}
