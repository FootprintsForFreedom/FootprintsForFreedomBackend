//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

//import Vapor
//import VaporSMTPKit
//
//extension SMTPCredentials {
//    static var `default`: SMTPCredentials {
//        let hostname = Environment.emailHost
//        let email = Environment.emailAdress
//        let password = Environment.emailPassword
//        let port: Int = {
//            var port: Int = 587
//            if let parameter = Environment.emailPort, let newPort = Int(parameter) {
//                port = newPort
//            }
//            return port
//        }()
//            
//        return SMTPCredentials(
//            hostname: hostname,
//            port: port,
//            ssl: .startTLS(configuration: .default),
//            email: email,
//            password: password
//        )
//    }
//}
