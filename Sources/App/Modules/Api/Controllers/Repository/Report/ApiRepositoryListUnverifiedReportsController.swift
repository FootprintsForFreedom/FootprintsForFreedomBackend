//
//  ApiRepositoryListUnverifiedReportsController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol ApiRepositoryListUnverifiedReportsController: RepositoryController where DatabaseModel: Reportable {
    associatedtype ReportListObject: Codable
    
    func beforeListUnverifiedReports(_ req: Request) async throws
    func listUnverifiedReportsApi(_ req: Request) async throws -> Page<ReportListObject>
    func listUnverifiedReportsOutput(_ req: Request, _ repository: DatabaseModel, _ reports: Page<Report>) async throws -> Page<ReportListObject>
    func listUnverifiedReportsOutput(_ req: Request,  _ repository: DatabaseModel, _ report: Report) async throws -> ReportListObject
    func setupListUnverifiedReportsRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryListUnverifiedReportsController {
    func beforeListUnverifiedReports(_ req: Request) async throws { }
    
    func listUnverifiedReportsApi(_ req: Request) async throws -> Page<ReportListObject> {
        try await beforeListUnverifiedReports(req)
        
        let repository = try await repository(req)
        
        let unverifiedReports = try await repository._$reports
            .query(on: req.db)
            .filter(\._$status == .pending)
            .sort(\._$updatedAt, .ascending) // oldest first
            .paginate(for: req)
        
        return try await listUnverifiedReportsOutput(req, repository, unverifiedReports)
    }
    
    func listUnverifiedReportsOutput(_ req: Request, _ repository: DatabaseModel, _ reports: Page<Report>) async throws -> Page<ReportListObject> {
        return try await reports
            .concurrentMap { report in
                return try await listUnverifiedReportsOutput(req, repository, report)
            }
    }
    
    func setupListUnverifiedReportsRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes
            .grouped("reports")
            .get("unverified", use: listUnverifiedReportsApi)
    }
}

extension ApiRepositoryListUnverifiedReportsController where ReportListObject == AppApi.Report.List {
    func beforeListUnverifiedReports(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func listUnverifiedReportsOutput(_ req: Request,  _ repository: DatabaseModel, _ report: Report) async throws -> ReportListObject {
        return try .init(
            id: repository.requireID(),
            title: report.title,
            slug: report.slug
        )
    }
}
