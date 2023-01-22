//
//  RedirectTest.swift
//  
//
//  Created by niklhut on 17.01.23.
//

@testable import App
import XCTVapor
import Fluent

protocol RedirectTest: LanguageTest { }

extension RedirectTest {
    var redirectPath: String { "api/v1/redirects/" }
    
    func createNewRedirect(
        source: String = "this/is/source/\(UUID())",
        destination: String = "and/it/goes/to/\(UUID())"
    ) async throws -> RedirectModel {
        try await RedirectModel.createWith(source: source, destination: destination, on: app.db)
    }
}

extension RedirectModel {
    static func createWith(
        source: String,
        destination: String,
        on db: Database
    ) async throws -> Self {
        let redirect = self.init(source: source, destination: destination)
        try await redirect.create(on: db)
        return redirect
    }
}
