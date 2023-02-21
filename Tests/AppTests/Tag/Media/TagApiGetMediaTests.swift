//
//  TagApiGetMediaTests.swift
//  
//
//  Created by niklhut on 21.02.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiGetMediaTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulGetMediaForTag() async throws {
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia(verified: true)
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on media should return ok and the media with the tag")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, media.repository.id)
                XCTAssert(content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNotNil(content.detailId)
            }
            .test()
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get media for tag should return ok and the media for the tag.")
            .get(tagPath.appending("\(tag.repository.requireID())/media/?per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
}
