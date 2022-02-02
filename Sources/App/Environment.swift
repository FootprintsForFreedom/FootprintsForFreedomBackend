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
    
    static let emailHost = Self.get("EMAIL_HOST")!
    static let emailAdress = Self.get("EMAIL_ADRESS")!
    static let emailPassword = Self.get("EMAIL_PASSWORD")!
    static let emailPort = Self.get("EMAIL_PORT")
    static let emailSenderName = Self.get("EMAIL_SENDER_NAME")!
}
