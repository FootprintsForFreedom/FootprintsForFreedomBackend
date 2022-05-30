//
//  TagApiDeleteTests.swift
//  
//
//  Created by niklhut on 27.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiDeleteTests: AppTestCase, TagTest {
    func testSuccessfulDeleteUnverifiedTagAsModerator() async throws {
        // Get original tag count
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        let (tagRepository, _) = try await createNewTag()
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New tag count should be one less than original tag count
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newTagCount, tagCount)
    }
    
    func testSuccessfulDeleteVerifiedTagAsModerator() async throws {
        // Get original tag count
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        let (tagRepository, _) = try await createNewTag(verified: true)
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New tag count should be one less than original tag count
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newTagCount, tagCount)
    }
    
    func testDeleteTagRepositoryDeletesDetails() async throws {
        // Get original tag count
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let detailCount = try await TagDetailModel.query(on: app.db).count()
        
        let (tagRepository, _) = try await createNewTag(verified: true)
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New tag count should be one less than original tag count
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newDetailCount = try await TagDetailModel.query(on: app.db).count()
        XCTAssertEqual(newTagCount, tagCount)
        XCTAssertEqual(newDetailCount, detailCount)
    }
    
    func testDeleteUnverifiedTagAsCreatorFails() async throws {
        let user = try await getUser(role: .user)
        let userToken = try user.generateToken()
        try await userToken.create(on: app.db)
        let (tagRepository, _) = try await createNewTag(verified: true)
        
        try app
            .describe("A user should not be able to delete a tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(userToken.value)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteUnverifiedTagAsUserFails() async throws {
        let (tagRepository, _) = try await createNewTag(verified: true)
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("A user should not be able to delete a tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteTagWithoutTokenFails() async throws {
        let (tagRepository, _) = try await createNewTag(verified: true)
        
        try app
            .describe("Delete tag without token fails")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingTagFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Delete nonexistand tag fails")
            .delete(tagPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    // TODO: test delete mediaTag/waypointTag when deleting tag itself
    // TODO: delete tag pirvot when deleting media/waypoint/tag -> cascase on pivot?
}
