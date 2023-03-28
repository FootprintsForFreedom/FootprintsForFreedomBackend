//
//  StaticContentApiDeleteUserTests.swift
//  
//
//  Created by niklhut on 10.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class StaticContentApiDeleteUserTests: AppTestCase, StaticContentTest, UserTest {
    func testDeleteUserSetsUserIdToNil() async throws {
        let adminToken = try await getToken(for: .admin)
        let (user, token) = try await createNewUserWithToken()
        let (repository, detail) = try await createNewStaticContent(userId: user.requireID())
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("User should be able to delete himself; Delete user should set staticContent user id to nil")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.noContent)
            .test()
        
        try app
            .describe("Getting the staticContent with the deleted user should be successful")
            .get(staticContentPath.appending(repository.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.text, detail.text)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, detail.id!)
            }
            .test()
        
        let updatedDetail = try await StaticContentDetailModel.find(detail.requireID(), on: app.db)!
        try await updatedDetail.$user.load(on: app.db)
        XCTAssertEqual(updatedDetail.$user.id, nil)
    }
}
