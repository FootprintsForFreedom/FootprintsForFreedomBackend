//
//  MediaTest.swift
//  
//
//  Created by niklhut on 14.05.22.
//

@testable import App
import XCTVapor
import Fluent

protocol MediaTest: WaypointTest { }

extension MediaTest {
    var mediaPath: String { "api/media/" }
    
    func createNewMedia(
        title: String = "New Media Title \(UUID())",
        detailText: String = "New Media Desscription",
        source: String = "New Media Source",
        group: Media.Detail.Group = .image,
        verified: Bool = false,
        waypointId: UUID? = nil,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: MediaRepositoryModel, detail: MediaDetailModel, file: MediaFileModel) {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let languageId: UUID = try await {
            if let languageId = languageId {
                return languageId
            } else {
                return try await createLanguage().requireID()
            }
        }()
        
        let waypointId: UUID = try await {
            if let waypointId = waypointId {
                return waypointId
            } else {
                return try await createNewWaypoint().repository.requireID()
            }
        }()
        
        let mediaRepository = MediaRepositoryModel()
        mediaRepository.$waypoint.id = waypointId
        try await mediaRepository.create(on: app.db)
        
        let mediaFile = try await MediaFileModel.createWith(
            mediaDirectory: UUID().uuidString,
            group: group,
            userId: userId,
            on: app.db
        )
        
        let mediaDetail = try await MediaDetailModel.createWith(
            verified: verified,
            title: title,
            detailText: detailText,
            source: source,
            languageId: languageId,
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: userId,
            on: app.db
        )
        
        return (mediaRepository, mediaDetail, mediaFile)
    }
}

extension MediaFileModel {
    static func createWith(
        mediaDirectory: String,
        group: Media.Detail.Group,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let mediaFile = self.init(
            mediaDirectory: mediaDirectory,
            group: group,
            userId: userId
        )
        try await mediaFile.create(on: db)
        return mediaFile
    }
}

extension MediaDetailModel {
    static func createWith(
        verified: Bool,
        title: String,
        slug: String? = nil,
        detailText: String,
        source: String,
        languageId: UUID,
        repositoryId: UUID,
        fileId: UUID,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let mediaDetail = self.init(
            verified: verified,
            title: title,
            slug: slug,
            detailText: detailText,
            source: source,
            languageId: languageId,
            repositoryId: repositoryId,
            fileId: fileId,
            userId: userId
        )
        try await mediaDetail.create(on: db)
        return mediaDetail
    }
}
