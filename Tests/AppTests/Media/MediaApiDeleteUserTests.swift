//
//  MediaApiDeleteUserTests.swift
//  
//
//  Created by niklhut on 30.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiDeleteUserTests: AppTestCase, MediaTest, UserTest {
    func testDeleteUserSetsUserIdToNil() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (user, token) = try await createNewUserWithToken()
        let (mediaRepository, media, file) = try await createNewMedia(verified: true, userId: user.requireID())
        try await media.$language.load(on: app.db)
        
        try app
            .describe("User should be able to delete himself; Delete user should set media detail user id to nil")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.noContent)
            .test()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified media with deleted user should return ok and more details")
            .get(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, mediaRepository.id)
                XCTAssertEqual(content.title, media.title)
                XCTAssertEqual(content.detailText, media.detailText)
                XCTAssertEqual(content.languageCode, media.language.languageCode)
                XCTAssertEqual(content.fileType, file.fileType)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, media.id!)
            }
            .test()
        
        let updatedDetail = try await MediaDetailModel.find(media.requireID(), on: app.db)!
        try await updatedDetail.$user.load(on: app.db)
        XCTAssertEqual(updatedDetail.$user.id, nil)
        
        let updatedFile = try await MediaFileModel.find(file.requireID(), on: app.db)!
        try await updatedFile.$user.load(on: app.db)
        XCTAssertEqual(updatedFile.$user.id, nil)
    }
}
