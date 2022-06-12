//
//  File.swift
//  
//
//  Created by niklhut on 02.02.22.
//

import Vapor

extension Environment {
    static let dbHost = Self.get("DATABASE_HOST")!
    static let dbPort = Self.get("DATABASE_PORT")
    static let pgUser = Self.get("POSTGRES_USER")!
    static let pgPassword = Self.get("POSTGRES_PASSWORD") ?? ""
    static let pgDbName = Self.get("POSTGRES_DB")!
    
    static let appUrl = Self.get("APP_URL")!
    static let appName = Self.get("APP_NAME")!
    
    static let emailAddress = Self.get("SMTP_USERNAME")!
}
