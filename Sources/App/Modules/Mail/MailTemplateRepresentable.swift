//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol MailTemplateRepresentable {
    func send(on req: Request) async throws
    func sendAction(_ req: Request) async throws
}

extension MailTemplateRepresentable {
    func send(on req: Request) async throws {
        if req.application.environment != .testing {
            try await sendAction(req)
        }
    }
}
