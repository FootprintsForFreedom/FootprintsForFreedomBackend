//
//  ApiRepositoryReportController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol ApiRepositoryReportController:
    ApiRepositoryCreateReportController,
    ApiRepositoryListUnverifiedReportsController,
    ApiRepositoryVerifyReportController
{
    func setupReportRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryReportController {
    func setupReportRoutes(_ routes: RoutesBuilder) {
        setupCreateReportRoutes(routes)
        setupListUnverifiedReportsRoutes(routes)
        setupVerifyReportRoutes(routes)
    }
}
