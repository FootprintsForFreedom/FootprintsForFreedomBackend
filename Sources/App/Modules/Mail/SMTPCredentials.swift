//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import VaporSMTPKit

extension SMTPCredentials {
    static var `default`: SMTPCredentials {
        let hostname = Environment.get("EMAIL_HOST")!
        let email = Environment.get("EMAIL_ADRESS")!
        let password = Environment.get("EMAIL_PASSWORD")!
        let port: Int = {
            var port: Int = 587
            if let parameter = Environment.get("EMAIL_PORT"), let newPort = Int(parameter) {
                port = newPort
            }
            return port
        }()
            
        return SMTPCredentials(
            hostname: hostname,
            port: port,
            ssl: .startTLS(configuration: .default),
            email: email,
            password: password
        )
    }
}
