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
    func createNewMedia(
        title: String = "New Media Title \(UUID())",
        description: String = "New Media Desscription",
        source: String = "New Media Source",
        group: Media.Media.Group = .image,
        verified: Bool = false,
        waypointId: UUID? = nil,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: MediaRepositoryModel, description: MediaDescriptionModel, file: MediaFileModel) {
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
        
        let mediaDescription = try await MediaDescriptionModel.createWith(
            verified: verified,
            title: title,
            description: description,
            source: source,
            languageId: languageId,
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: userId,
            on: app.db
        )
        
        return (mediaRepository, mediaDescription, mediaFile)
    }
}

extension MediaFileModel {
    static func createWith(
        mediaDirectory: String,
        group: Media.Media.Group,
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

extension MediaDescriptionModel {
    static func createWith(
        verified: Bool,
        title: String,
        description: String,
        source: String,
        languageId: UUID,
        repositoryId: UUID,
        fileId: UUID,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let mediaDescription = self.init(
            verified: verified,
            title: title,
            description: description,
            source: source,
            languageId: languageId,
            repositoryId: repositoryId,
            fileId: fileId,
            userId: userId
        )
        try await mediaDescription.create(on: db)
        return mediaDescription
    }
}
