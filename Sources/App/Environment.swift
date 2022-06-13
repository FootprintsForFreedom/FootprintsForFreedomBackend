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
    
    /// The lifetime of soft deleted models.
    ///
    /// It is used to determine when to delete a soft deleted model in the cleanup job.
    /// If no value is set the soft deleted models won't be deleted.
    static let softDeletedLifetime: Int? = {
        if let softDeletedLifetime = Self.get("SOFT_DELETED_LIFETIME") {
            return Int(softDeletedLifetime)
        }
        return nil
    }()
}
