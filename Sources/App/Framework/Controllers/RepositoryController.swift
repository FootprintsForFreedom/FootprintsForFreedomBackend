//
//  RepositoryController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

public protocol RepositoryController: ModelController  {
    /// Gets the model slug from a request.
    /// - Parameter req: The request containing the model slug.
    /// - Returns: The model slug.
    func slug(_ req: Request) throws -> String
}

extension RepositoryController {
    func slug(_ req: Request) throws -> String {
        guard
            let slug = req.parameters.get(ApiModel.pathIdKey),
            slug == slug.slugify()
        else {
            throw Abort(.badRequest)
        }
        return slug
    }
}
