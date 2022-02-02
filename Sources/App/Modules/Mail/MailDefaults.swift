//
//  MailDefaults.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SMTPKitten

struct MailDefaults {
    static var sender: MailUser {
        let email = Environment.emailAdress
        let name = Environment.emailSenderName
        return MailUser(name: name, email: email)
    }
}
