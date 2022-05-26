//
//  RepositoryVerificationController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

protocol RepositoryVerificationController:
    ApiRepositoryDetailChangesController,
    ApiListRepositoriesWithUnverifiedDetailsController,
    ApiRepositoryListUnverifiedDetailsController,
    ApiRepositoryVerifyDetailController
{
    func setupVerificationRoutes(_ routes: RoutesBuilder)
}

extension RepositoryVerificationController {
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        setupDetailChangesRoutes(routes)
        setuplistRepositoriesWithUnverifiedDetailsRoutes(routes)
        setupListUnverifiedDetailsRoutes(routes)
        setupVerifyDetailRoutes(routes)
    }
}
