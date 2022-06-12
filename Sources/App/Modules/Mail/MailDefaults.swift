//
//  MailDefaults.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SwiftSMTP

struct MailDefaults {
    static var sender: Email.Contact {
        let email = Environment.emailAddress
        let name = Environment.appName
        return Email.Contact(name: name, emailAddress: email)
    }
}
