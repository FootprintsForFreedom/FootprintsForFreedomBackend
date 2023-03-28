//
//  UserRequestPasswordResetMail.swift
//
//
//  Created by niklhut on 03.02.22.
//

import Vapor
import SwiftSMTPVapor

struct UserRequestPasswordResetMail: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.passwordResetSlug }
}
