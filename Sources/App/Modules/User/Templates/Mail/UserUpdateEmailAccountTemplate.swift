//
//  UserUpdateEmailAccountTemplate.swift
//
//
//  Created by niklhut on 03.02.22.
//

import Vapor
import SwiftSMTPVapor

struct UserUpdateEmailAccountTemplate: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.updateEmailSlug }
}
