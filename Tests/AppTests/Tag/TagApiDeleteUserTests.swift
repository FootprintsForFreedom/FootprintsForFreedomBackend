//
//  TagApiDeleteUserTests.swift
//  
//
//  Created by niklhut on 30.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiDeleteUserTests: AppTestCase, TagTest, UserTest {
    func testDeleteUserSetsUserIdToNil() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (user, token) = try await createNewUserWithToken()
        let (repository, detail) = try await createNewTag(verifiedAt: Date(), userId: user.requireID())
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("User should be able to delete himself; Delete user should set tag user id to nil")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.noContent)
            .test()
        
        try app
            .describe("Getting the tag with the deleted user should be successful")
            .get(tagPath.appending(repository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, detail.id!)
            }
            .test()
        
        let updatedDetail = try await TagDetailModel.find(detail.requireID(), on: app.db)!
        try await updatedDetail.$user.load(on: app.db)
        XCTAssertEqual(updatedDetail.$user.id, nil)
    }
}
