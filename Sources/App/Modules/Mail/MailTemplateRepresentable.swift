//
//  MailTemplateRepresentable.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SwiftSMTPVapor

protocol MailTemplateRepresentable {
    static var staticContentSlug: String { get }
    
    static func send(for user: UserAccountModel, on req: Request) async throws
}

extension MailTemplateRepresentable {
    static func send(for user: UserAccountModel, on req: Request) async throws {
        let recipient = Email.Contact(name: user.name, emailAddress: user.email)
        
        guard
            let mailRepository = try await StaticContentRepositoryModel
                .query(on: req.db)
                .filter(\.$slug, .equal, staticContentSlug)
                .first(),
            let detail = try await mailRepository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db)
        else {
            req.logger.log(level: .critical, "User verify account mail not found")
            throw Abort(.internalServerError)
        }
        
        guard let userToken = user.verificationToken?.value else {
            throw Abort(.internalServerError)
        }
        let verificationLink = "\(Environment.appUrl)/api/user/accounts/\(user.id!)/verify?token=\(userToken)"
        
        let subject = detail.title
            .replacingOccurrences(of: StaticContent.Snippet.username.rawValue, with: user.name)
            .replacingOccurrences(of: StaticContent.Snippet.appName.rawValue, with: Environment.appName)
        
        let bodyText = detail.text
            .replacingOccurrences(of: StaticContent.Snippet.username.rawValue, with: user.name)
            .replacingOccurrences(of: StaticContent.Snippet.verificationLink.rawValue, with: verificationLink)
            .replacingOccurrences(of: StaticContent.Snippet.appName.rawValue, with: Environment.appName)
        
        let mail = Email(
            sender: MailDefaults.sender,
            recipients: [recipient],
            subject: subject,
            body: .plain(bodyText)
        )
        
        if req.application.environment != .testing && Environment.sendMails == true {
            try await req.swiftSMTP.mailer.send(email: mail)
        }
    }
}
