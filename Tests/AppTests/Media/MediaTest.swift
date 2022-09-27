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
    var mediaPath: String { "api/v1/media/" }
    
    func createNewMedia(
        title: String = "New Media Title \(UUID())",
        detailText: String = "New Media Description",
        source: String = "New Media Source",
        group: Media.Detail.Group = .image,
        verifiedAt: Date? = nil,
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
                return try await LanguageModel
                    .query(on: app.db)
                    .filter(\.$languageCode == "de")
                    .first()!
                    .requireID()
            }
        }()
        
        let waypointId: UUID = try await {
            if let waypointId = waypointId {
                return waypointId
            } else {
                return try await createNewWaypoint(languageId: languageId).repository.requireID()
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
            verifiedAt: verifiedAt,
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
        verifiedAt: Date?,
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
            verifiedAt: verifiedAt,
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
    
    @discardableResult
    func updateWith(
        verifiedAt: Date? = nil,
        title: String = "Updated Media Title \(UUID())",
        slug: String? = nil,
        detailText: String = "Updated Media Description",
        source: String = "Updated Media Source",
        languageId: UUID? = nil,
        fileId: UUID? = nil,
        userId: UUID? = nil,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let mediaDetail = Self.init(
            verifiedAt: verifiedAt,
            title: title,
            slug: slug,
            detailText: detailText,
            source: source,
            languageId: languageId ?? self.$language.id,
            repositoryId: self.$repository.id,
            fileId: fileId ?? self.$media.id,
            userId: userId ?? self.$user.id!
        )
        try await mediaDetail.create(on: db)
        return mediaDetail
    }
}
