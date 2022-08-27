//
//  Environment.swift
//  
//
//  Created by niklhut on 02.02.22.
//

import Vapor

extension Environment {
    /// The database host.
    static let dbHost = Self.get("DATABASE_HOST")!
    /// The database port.
    static let dbPort = Self.get("DATABASE_PORT")
    /// The postgres username.
    static let pgUser = Self.get("POSTGRES_USER")!
    /// The postgres password.
    ///
    /// If no postgres password is set in the environment no password is returned.
    static let pgPassword = Self.get("POSTGRES_PASSWORD") ?? ""
    /// The postgres database name.
    static let pgDbName = Self.get("POSTGRES_DB")!
    
    static let redisUrl = Self.get("REDIS_HOST")!
    
    /// The app url.
    static let appUrl = Self.get("APP_URL")!
    /// The app name.
    static let appName = Self.get("APP_NAME")!
    
    /// The email address used for sending mails.
    static let emailAddress = Self.get("SMTP_USERNAME")!
    
    /// Wether or not the backend system should send emails.
    static let sendMails: Bool = {
        guard let sendMailsString = Self.get("SEND_MAILS") else {
            return false
        }
        return sendMailsString == "true"
    }()
    
    /// The lifetime of soft deleted models in days.
    ///
    /// It is used to determine when to delete a soft deleted model in the cleanup job.
    /// 
    /// If no value is set the soft deleted models won't be deleted.
    static let softDeletedLifetime: Int? = {
        if let softDeletedLifetime = Self.get("SOFT_DELETED_LIFETIME") {
            return Int(softDeletedLifetime)
        }
        return nil
    }()
    
    /// The lifetime of old verified models in days.
    ///
    /// It is used to determine when to delete an old verified model in the cleanup job.
    ///
    /// An old verified model is a verified model, that is no longer in use since it was updated or patched.
    ///
    /// If no value is set the old verified models won't be deleted.
    static let oldVerifiedLifetime: Int? = {
        if let oldVerifiedLifetime = Self.get("OLD_VERIFIED_LIFETIME") {
            return Int(oldVerifiedLifetime)
        }
        return nil
    }()
}
