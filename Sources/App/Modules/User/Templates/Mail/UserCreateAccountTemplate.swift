//
//  UserCreateAccountTemplate.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SwiftSMTPVapor

struct UserCreateAccountTemplate: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.createAccountSlug }
}
