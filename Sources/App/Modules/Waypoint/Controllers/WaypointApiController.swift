//
//  WaypointApiController.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Vapor
import Fluent
import AppApi
import ElasticsearchNIOClient
import MMDB

extension Waypoint.Detail.List: Content { }
extension Waypoint.Detail.ListWrapper: Content { }
extension Waypoint.Detail.Detail: Content { }

struct WaypointApiController: ApiElasticDetailController, ApiElasticPagedListController, ApiRepositoryCreateController, ApiRepositoryUpdateController, ApiRepositoryPatchController, ApiDeleteController {
    typealias ApiModel = Waypoint.Detail
    typealias DatabaseModel = WaypointRepositoryModel
    typealias ElasticModel = WaypointSummaryModel.Elasticsearch
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("detailText")
        KeyedContentValidator<Waypoint.Location>.location("location")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("detailText")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: true)
        KeyedContentValidator<String>.required("detailText", optional: true)
        KeyedContentValidator<Waypoint.Location>.location("location", optional: true)
        KeyedContentValidator<String>.required("idForWaypointDetailToPatch")
    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("waypoints")
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
    
    // MARK: - List
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listWrapper)
    }
    
    func listWrapper(_ req: Request) async throws -> Waypoint.Detail.ListWrapper {
        /// Contains all values that can be encoded into the query of this request
        struct QueryValues: Encodable {
            let latitude: Double
            let longitude: Double
            let preferredLanguage: String?
            let page: Int
            let per: Int
        }
        
        let location: Waypoint.Location
        let decodedLocation = try req.query.decode(Waypoint.Request.GetList.self)
        if decodedLocation.latitude == nil || decodedLocation.longitude == nil {
            if let userIp = req.peerAddress?.ipAddress,
               case let .value(result) = req.mmdb.search(address: userIp),
               case let .map(map) = result,
               case let .map(locationMap) = map["location"],
               case let .double(latitude) = locationMap["latitude"],
               case let .double(longitude) = locationMap["longitude"] {
                // set location from ip address
                location = Waypoint.Location(latitude: latitude, longitude: longitude)
            } else {
                // set default location
                location = Waypoint.Location(latitude: 49.872222, longitude: 8.652778)
            }
            let pageRequest = try req.pageRequest
            let preferredLanguage = try req.preferredLanguageCode()
            // Encode the query values struct since encoding only the location would reset the query and therefore delete the page request
            try req.query.encode(QueryValues(latitude: location.latitude, longitude: location.longitude, preferredLanguage: preferredLanguage, page: pageRequest.page, per: pageRequest.per))
        } else {
            // set location sent with request
            location = .init(latitude: decodedLocation.latitude!, longitude: decodedLocation.longitude!)
        }
        
        let items = try await listApi(req)
        return .init(userLocation: location, items: items)
    }
    
    func sortList(_ sort: inout [[String: Any]], on req: Request, with parameters: Waypoint.Location) async throws {
        let geoSort = [
            "_geo_distance" : [
                "location": [parameters.latitude, parameters.longitude],
                "order" : "asc",
                "unit" : "km",
                "mode" : "min",
                "distance_type" : "arc",
                "ignore_unmapped": true
            ]
        ]
        sort.insert(geoSort, at: sort.startIndex)
    }
    
    func listOutput(_ req: Request, _ model: WaypointSummaryModel.Elasticsearch) -> Waypoint.Detail.List {
        .init(
            id: model.id,
            title: model.title,
            slug: model.slug,
            location: .init(latitude: model.location.lat, longitude: model.location.lon)
        )
    }
    
    // MARK: - Detail
    
    func detailOutput(_ req: Request, _ model: WaypointSummaryModel.Elasticsearch, _ availableLanguageCodes: [String]) async throws -> Waypoint.Detail.Detail {
        let tagList = try await model.getTagList(preferredLanguageCode: req.preferredLanguageCode(), on: req.elastic) // TODO: we get the preferred language code twice...
        return .init(
            id: model.id,
            title: model.title,
            slug: model.slug,
            detailText: model.detailText,
            location: .init(latitude: model.location.lat, longitude: model.location.lon),
            tags: tagList,
            languageCode: model.languageCode,
            availableLanguageCodes: availableLanguageCodes,
            detailId: model.detailId,
            locationId: model.locationId
        )
    }
    
    func detailOutput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: WaypointDetailModel, _ location: WaypointLocationModel) async throws -> Waypoint.Detail.Detail {
        try await detail.$language.load(on: req.db)
        return try await .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            location: location.location,
            tags: repository.tagList(req),
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(req.db),
            detailId: detail.requireID(),
            locationId: location.requireID()
        )
    }
    
    // MARK: - Create
    
    func createApi(_ req: Request) async throws -> Response {
        let input = try await getCreateInput(req)
        let repository = DatabaseModel()
        try await createRepositoryInput(req, repository, input)
        try await create(req, repository)
        let detail = Detail()
        let location = WaypointLocationModel()
        try await createInput(req, repository, detail, location, input)
        detail.slug = try await detail.generateSlug(with: .day, on: req.db)
        try await repository.$details.create(detail, on: req.db)
        try await repository.$locations.create(location, on: req.db)
        return try await createResponse(req, repository, detail, location)
    }
    
    func beforeCreate(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func createInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail, _ input: Waypoint.Detail.Create) async throws {
        fatalError()
    }
    
    func createInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail, _ location: WaypointLocationModel, _ input: Waypoint.Detail.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        detail.title = input.title
        detail.detailText = input.detailText
        detail.$language.id = languageId
        detail.$user.id = user.id
        
        location.latitude = input.location.latitude
        location.longitude = input.location.longitude
        location.$user.id = user.id
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func createResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        fatalError()
    }
    
    func createResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointDetailModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(status: .created, for: req)
    }
    
    // MARK: - Update
    
    func beforeUpdate(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func updateInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: WaypointDetailModel, _ input: Waypoint.Detail.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        detail.title = input.title
        detail.detailText = input.detailText
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    func updateResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointDetailModel) async throws -> Response {
        guard let location = try await repository.$locations.firstFor(needsToBeVerified: false, on: req.db) else {
            throw Abort(.internalServerError)
        }
        return try await detailOutput(req, repository, waypoint, location).encodeResponse(for: req)
    }
    
    // MARK: - Patch
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        try await beforePatch(req, repository)
        let (detail, location) = try await patchInput(req, repository, input)
        try await afterPatch(req, repository)
        return try await patchResponse(req, repository, detail, location)
    }
    
    func beforePatch(_ req: Request, _ model: WaypointRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func patchInput(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail, _ input: Waypoint.Detail.Patch) async throws {
        fatalError()
    }
    
    func patchInput(_ req: Request, _ repository: WaypointRepositoryModel, _ input: Waypoint.Detail.Patch) async throws -> (WaypointDetailModel, WaypointLocationModel){
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let waypointToPatch = try await WaypointDetailModel.find(input.idForWaypointDetailToPatch, on: req.db) else {
            throw Abort(.badRequest, reason: "No waypoint with the given id could be found")
        }
        
        guard input.title != nil || input.detailText != nil || input.location != nil else {
            throw Abort(.badRequest)
        }
        
        var waypoint: WaypointDetailModel! = nil
        if input.title != nil || input.detailText != nil {
            let newWaypoint = WaypointDetailModel()
            newWaypoint.$user.id = user.id
            newWaypoint.$language.id = waypointToPatch.$language.id
            newWaypoint.title = input.title ?? waypointToPatch.title
            newWaypoint.slug = try await newWaypoint.generateSlug(with: .day, on: req.db)
            newWaypoint.detailText = input.detailText ?? waypointToPatch.detailText
            try await repository.$details.create(newWaypoint, on: req.db)
            waypoint = newWaypoint
        } else {
            waypoint = waypointToPatch
        }
        
        var location: WaypointLocationModel! = nil
        if let inputLocation = input.location {
            let newLocation = try WaypointLocationModel(
                latitude: inputLocation.latitude,
                longitude: inputLocation.longitude,
                repositoryId: repository.requireID(),
                userId: user.id
            )
            try await newLocation.create(on: req.db)
            location = newLocation
        } else {
            guard let storedLocation = try await repository.$locations.firstFor(needsToBeVerified: false, on: req.db) else {
                throw Abort(.internalServerError)
            }
            location = storedLocation
        }
        return (waypoint, location)
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func patchResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ detail: Detail) async throws -> Response {
        fatalError()
    }
    
    func patchResponse(_ req: Request, _ repository: WaypointRepositoryModel, _ waypoint: WaypointDetailModel, _ location: WaypointLocationModel) async throws -> Response {
        try await detailOutput(req, repository, waypoint, location).encodeResponse(for: req)
    }
    
    // MARK: - Delete
    
    // TODO: make sure cannot delete first location or waypoint model since then it would be empty
    // Instead prompt the user to sumbmit a change and verify subsequently
    // but then also remove the previously sumbmitted not verifed text model
    
    // or delete the entire repository when deleting first waypoint
    // TODO: also enable user to delete own waypoint model/location
    // also do that with media
    
    func beforeDelete(_ req: Request, _ repository: WaypointRepositoryModel) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func afterDelete(_ req: Request, _ repository: WaypointRepositoryModel) async throws {
        try await WaypointSummaryModel.Elasticsearch.delete(allDetailsWithRepositoryId: repository.requireID(), on: req)
    }
}
