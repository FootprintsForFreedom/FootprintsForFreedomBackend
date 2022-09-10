//
//  ApiRepositoryListUnverifiedReportsController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

/// Streamlines listing unverified repository reports.
protocol ApiRepositoryListUnverifiedReportsController: RepositoryController where DatabaseModel: Reportable {
    /// The codable report list object.
    associatedtype ReportListObject: Codable
    
    /// Action performed prior to listing the unverified reports.
    /// - Parameter req: The request on which to get the unverified repository reports.
    func beforeListUnverifiedReports(_ req: Request) async throws
    
    /// The list unverified repository reports action.
    /// - Parameter req: The request on which to find the unverified repository reports.
    /// - Returns: A paged list of the unverified repository reports.
    func listUnverifiedReportsApi(_ req: Request) async throws -> Page<ReportListObject>
    
    /// The output for the unverified reports list.
    /// - Parameters:
    ///   - req: The request on which the reports list was requested.
    ///   - repository: The reported repository.
    ///   - reports: The unverified reports to be returned.
    /// - Returns: A paged list of the unverified repository reports.
    func listUnverifiedReportsOutput(_ req: Request, _ repository: DatabaseModel, _ reports: Page<Report>) async throws -> Page<ReportListObject>
    
    /// The output for one unverified report.
    /// - Parameters:
    ///   - req: The request on which the report was loaded.
    ///   - repository: The reported repository.
    ///   - report: The report to be returned
    /// - Returns: A list object of the report.
    func listUnverifiedReportsOutput(_ req: Request,  _ repository: DatabaseModel, _ report: Report) async throws -> ReportListObject
    
    /// Sets up the list unverified reports route.
    /// - Parameter routes: The routes on which to setup the unverified reports routes.
    func setupListUnverifiedReportsRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryListUnverifiedReportsController {
    func beforeListUnverifiedReports(_ req: Request) async throws { }
    
    func listUnverifiedReportsApi(_ req: Request) async throws -> Page<ReportListObject> {
        try await beforeListUnverifiedReports(req)
        
        let repository = try await repository(req)
        
        let unverifiedReports = try await repository._$reports
            .query(on: req.db)
            .filter(\._$verifiedAt == nil)
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
            id: report.requireID(),
            title: report.title,
            slug: report.slug
        )
    }
}
