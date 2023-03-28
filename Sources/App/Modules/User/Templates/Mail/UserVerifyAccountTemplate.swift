//
//  UserVerifyAccountTemplate.swift
//
//
//  Created by niklhut on 02.02.22.
//

import Vapor
import SwiftSMTPVapor

struct UserVerifyAccountTemplate: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.verifyAccountSlug }    
}
