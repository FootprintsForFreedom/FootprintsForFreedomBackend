//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

protocol MailTemplateRepresentable {
    func send(on req: Request) async throws
}
