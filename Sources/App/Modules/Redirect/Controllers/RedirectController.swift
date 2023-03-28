//
//  RedirectController.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Vapor
import Fluent

struct RedirectController {
    /// Sets up the model routes.
    /// - Parameter routes: The routes on which to setup the model routes.
    func setupRoutes(_ routes: RoutesBuilder) {
        routes.get(PathComponent.catchall, use: redirect)
    }
    
    func redirect(_ req: Request) async throws -> Response {
        let path = req.parameters.getCatchall().joined(separator: "/")
        if let redirect = try await RedirectModel
            .query(on: req.db)
            .filter(\.$source == path)
            .first() {
            let query = req.url.query ?? ""
            return req.redirect(to: redirect.destination.appending("?\(query)"), type: .permanent)
        }
        throw Abort(.internalServerError)
    }
}
