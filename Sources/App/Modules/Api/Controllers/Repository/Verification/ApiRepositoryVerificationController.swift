//
//  ApiRepositoryVerificationController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

/// Streamlines verifying repositories.
protocol ApiRepositoryVerificationController:
    ApiRepositoryDetailChangesController,
    ApiListRepositoriesWithUnverifiedDetailsController,
    ApiRepositoryListUnverifiedDetailsController,
    ApiRepositoryVerifyDetailController
{
    /// Sets up the verification routes.
    /// - Parameter routes: The routes on which to setup the verification routes.
    func setupVerificationRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryVerificationController {
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        setupDetailChangesRoutes(routes)
        setupListRepositoriesWithUnverifiedDetailsRoutes(routes)
        setupListUnverifiedDetailsRoutes(routes)
        setupVerifyDetailRoutes(routes)
    }
}
