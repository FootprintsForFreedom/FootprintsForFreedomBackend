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
    let mediaPath = "api/media/"
    
    func testSuccessfulDetailChanges() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDescription, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaFile = try await MediaFileModel.createWith(
            mediaDirectory: UUID().uuidString,
            group: .video,
            userId: user.requireID(),
            on: app.db
        )
        let secondMediaDescription = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Another different title",
            description: "This is a mew description",
            source: "Some other source",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: secondMediaFile.requireID(),
            userId: user.requireID(),
            on: app.db
        )
        try await mediaDescription.$user.load(on: app.db)
        try await secondMediaDescription.$user.load(on: app.db)
        
        try app
            .describe("Detail changes as moderator should be succesful and return ok and the changes")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDescription.requireID())&to=\(secondMediaDescription.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Repository.Changes.self) { content in
                XCTAssertEqual(content.fromUser.id, mediaDescription.user.id)
                XCTAssertEqual(content.toUser.id, secondMediaDescription.user.id)
                XCTAssertEqual(content.fromGroup, mediaFile.group)
                XCTAssertEqual(content.toGroup, secondMediaFile.group)
                XCTAssertEqual(content.fromFilePath, mediaFile.mediaDirectory)
                XCTAssertEqual(content.toFilePath, secondMediaFile.mediaDirectory)
            }
            .test()
    }
    
    func testDetailChangesAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDescription, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaDescription = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Another different title",
            description: "This is a mew description",
            source: "Some other source",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: user.requireID(),
            on: app.db
        )
        
        try app
            .describe("Detail changes as moderator should be succesful and return ok and the changes")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDescription.requireID())&to=\(secondMediaDescription.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDetailChangesWithoutTokenFails() async throws {
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDescription, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaDescription = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Another different title",
            description: "This is a mew description",
            source: "Some other source",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: user.requireID(),
            on: app.db
        )
        
        try app
            .describe("Detail changes as moderator should be succesful and return ok and the changes")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDescription.requireID())&to=\(secondMediaDescription.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDetailChangesMustContainFromId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (repository, description, _) = try await createNewMedia()
        
        try  app
            .describe("Detail changes request must contain from id field")
            .get(mediaPath.appending("\(repository.requireID())/changes/?to=\(description.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesMustContainToId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (repository, description, _) = try await createNewMedia()
        
        try  app
            .describe("Detail changes request must contain to id field")
            .get(mediaPath.appending("\(repository.requireID())/changes/?from=\(description.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesFromMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (_, mediaDescription, _) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let (mediaRepository2, mediaDescription2, _) = try await createNewMedia(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when from model is from other repository")
            .get(mediaPath.appending("\(mediaRepository2.requireID())/changes/?from=\(mediaDescription.requireID())&to=\(mediaDescription2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesToMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (waypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID())
        let (mediaRepository, mediaDescription, _) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let (_, mediaDescription2, _) = try await createNewMedia(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when to model is from other repository")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDescription.requireID())&to=\(mediaDescription2.requireID())"))
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
        let (mediaRepository, mediaDescription, mediaFile) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID())
        let secondMediaDescription = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Another different title",
            description: "This is a mew description",
            source: "Some other source",
            languageId: secondLanguage.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: user.requireID(),
            on: app.db
        )
        
        try app
            .describe("Detail changes should fail when models have different languages")
            .get(mediaPath.appending("\(mediaRepository.requireID())/changes/?from=\(mediaDescription.requireID())&to=\(secondMediaDescription.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
