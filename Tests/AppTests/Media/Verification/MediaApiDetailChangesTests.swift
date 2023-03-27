//
//  MediaApiDetailChangesTests.swift
//  
//
//  Created by niklhut on 18.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiDetailChangesTests: AppTestCase, MediaTest {
    func testSuccessfulDetailChanges() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDetail, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaFile = try await MediaFileModel.createWith(
            mediaDirectory: UUID().uuidString,
            fileType: .video,
            userId: user.requireID(),
            on: app.db
        )
        let secondMediaDetail = try await MediaDetailModel.createWith(
            verified: false,
            title: "Another different title \(UUID())",
            detailText: "This is a mew detailText",
            source: "Some other source",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: secondMediaFile.requireID(),
            userId: user.requireID(),
            on: self
        )
        try await mediaDetail.$user.load(on: app.db)
        try await secondMediaDetail.$user.load(on: app.db)
        
        try app
            .describe("Detail changes as moderator should be successful and return ok and the changes")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDetail.requireID())&to=\(secondMediaDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Repository.Changes.self) { content in
                XCTAssertEqual(content.fromUser?.id, mediaDetail.user?.id)
                XCTAssertEqual(content.toUser?.id, secondMediaDetail.user?.id)
                XCTAssertEqual(content.fromFilePath, mediaFile.relativeMediaFilePath)
                XCTAssertEqual(content.toFilePath, secondMediaFile.relativeMediaFilePath)
            }
            .test()
    }
    
    func testDetailChangesAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDetail, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaDetail = try await MediaDetailModel.createWith(
            verified: false,
            title: "Another different title \(UUID())",
            detailText: "This is a mew detailText",
            source: "Some other source",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: user.requireID(),
            on: self
        )
        
        try app
            .describe("Detail changes as moderator should be succesful and return ok and the changes")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDetail.requireID())&to=\(secondMediaDetail.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDetailChangesWithoutTokenFails() async throws {
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDetail, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaDetail = try await MediaDetailModel.createWith(
            verified: false,
            title: "Another different title \(UUID())",
            detailText: "This is a mew detailText",
            source: "Some other source",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: user.requireID(),
            on: self
        )
        
        try app
            .describe("Detail changes as moderator should be succesful and return ok and the changes")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDetail.requireID())&to=\(secondMediaDetail.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDetailChangesMustContainFromId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (repository, detail, _) = try await createNewMedia()
        
        try  app
            .describe("Detail changes request must contain from id field")
            .get(mediaPath.appending("\(repository.requireID())/changes/?to=\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesMustContainToId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (repository, detail, _) = try await createNewMedia()
        
        try  app
            .describe("Detail changes request must contain to id field")
            .get(mediaPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesFromMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (_, mediaDetail, _) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let (mediaRepository2, mediaDetail2, _) = try await createNewMedia(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when from model is from other repository")
            .get(mediaPath.appending("\(mediaRepository2.requireID())/changes/?from=\(mediaDetail.requireID())&to=\(mediaDetail2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesToMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDetail, _) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let (_, mediaDetail2, _) = try await createNewMedia(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when to model is from other repository")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDetail.requireID())&to=\(mediaDetail2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesWithModelsFromDifferntLanguagesFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let secondLanguage =  try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDetail, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaDetail = try await MediaDetailModel.createWith(
            verified: false,
            title: "Another different title \(UUID())",
            detailText: "This is a mew detailText",
            source: "Some other source",
            languageId: secondLanguage.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: user.requireID(),
            on: self
        )
        
        try app
            .describe("Detail changes should fail when models have different languages")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDetail.requireID())&to=\(secondMediaDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
