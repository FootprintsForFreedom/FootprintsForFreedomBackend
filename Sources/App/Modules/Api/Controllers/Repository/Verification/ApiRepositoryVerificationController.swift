//
//  ApiRepositoryVerificationController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor

protocol ApiRepositoryVerificationController:
    ApiRepositoryDetailChangesController,
    ApiListRepositoriesWithUnverifiedDetailsController,
    ApiRepositoryListUnverifiedDetailsController,
    ApiRepositoryVerifyDetailController
{
    func setupVerificationRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryVerificationController {
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        setupDetailChangesRoutes(routes)
        setuplistRepositoriesWithUnverifiedDetailsRoutes(routes)
        setupListUnverifiedDetailsRoutes(routes)
        setupVerifyDetailRoutes(routes)
    }
}
