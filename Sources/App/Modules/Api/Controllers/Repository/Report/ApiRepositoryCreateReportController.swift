//
//  ApiRepositoryReportController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

///Streamlines creating repository reports.
protocol ApiRepositoryCreateReportController: RepositoryController where DatabaseModel: Reportable {
    /// The codable report create object.
    associatedtype ReportCreateObject: Codable
    /// The report detail object content.
    associatedtype ReportDetailObject: Content
    /// The database detail object for the repository.
    associatedtype DetailObject: InitializableById
    
    /// Action performed prior to reporting the repository.
    /// - Parameter req: The request on which the repository will be reported.
    func beforeReport(_ req: Request) async throws
    
    /// The ``AsyncValidator``s which need to be fulfilled to report the repository.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled to report the repository.
    func reportValidators() -> [AsyncValidator]
    
    /// Processes the report input to create a report for the repository.
    /// - Parameters:
    ///   - req: The request on which the repository is reported.
    ///   - repository: The repository being reported.
    ///   - report: The new report.
    ///   - input: The input to be processed.
    func reportInput(_ req: Request, _ repository: DatabaseModel, _ report: Report, _ input: ReportCreateObject) async throws
    
    /// The report api action.
    /// - Parameter req: The request on which the repository is reported.
    /// - Returns: A response with the created report.
    func reportApi(_ req: Request) async throws -> Response
    
    /// The report detail response which will be returned.
    /// - Parameters:
    ///   - req: The request on which the repository is reported.
    ///   - repository: The repository being reported.
    ///   - report: The created report.
    /// - Returns: The report detail object to return as a response.
    func reportResponse(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws -> ReportDetailObject
    
    /// Sets up the create report routes.
    /// - Parameter routes: The routes on which to setup the create report routes.
    func setupCreateReportRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryCreateReportController {
    func beforeReport(_ req: Request) async throws { }
    
    @AsyncValidatorBuilder
    func reportValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("reason")
        KeyedContentValidator<UUID>.required("visibleDetailId")
    }
    
    func reportApi(_ req: Request) async throws -> Response {
        try await beforeReport(req)
        try await RequestValidator(reportValidators()).validate(req)
        
        let input = try req.content.decode(ReportCreateObject.self)
        let repository = try await repository(req)
        let report = Report()
        
        try await reportInput(req, repository, report, input)
        report.slug = try await report.generateSlug(with: .day, on: req.db)
        
        try await repository._$reports.create(report, on: req.db)
        return try await reportResponse(req, repository, report).encodeResponse(status: .created, for: req)
    }
    
    func setupCreateReportRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.post("reports", use: reportApi)
    }
}

extension AppApi.Report.Detail: Content { }

extension ApiRepositoryCreateReportController where ReportCreateObject == AppApi.Report.Create, ReportDetailObject == AppApi.Report.Detail<DetailObject> {
    func beforeReport(_ req: Request) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func reportInput(_ req: Request, _ repository: DatabaseModel, _ report: Report, _ input: ReportCreateObject) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let currentlyVisibleDetail = try await Detail
            .query(on: req.db)
            .filter(\._$id == input.visibleDetailId)
            .filter(\._$repository.$id == repository.requireID())
            .first()
        else {
            throw Abort(.badRequest)
        }
        
        report.title = input.title
        report.reason = input.reason
        report._$visibleDetail.id = try currentlyVisibleDetail.requireID()
        report._$user.id = user.id
    }
    
    func reportResponse(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws -> ReportDetailObject {
        return try await .init(
            id: repository.requireID(),
            title: report.title,
            slug: report.slug,
            reason: report.reason,
            visibleDetail: DetailObject(id: report._$visibleDetail.id, db: req.db),
            reportId: report.requireID()
        )
    }
}
