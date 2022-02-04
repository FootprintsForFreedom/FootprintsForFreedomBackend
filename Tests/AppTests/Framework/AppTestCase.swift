//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

@testable import App
import XCTVapor
import FluentSQLiteDriver

extension Environment {
    static let pgTestDbName = Self.get("POSTGRES_TEST_DB")!
}

open class AppTestCase: XCTestCase {
    var app: Application!
    
    struct UserLogin: Content {
        let email: String
        let password: String
    }
    
    func createTestApp() throws -> Application {
        let app = Application(.testing)
        
        try configure(app)
        app.databases.reinitialize()
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.databases.default(to: .sqlite)
//        app.databases.use(.postgres(
//            hostname: Environment.dbHost,
//            username: Environment.pgUser,
//            password: Environment.pgPassword,
//            database: Environment.pgTestDbName
//        ), as: .psql)
//        app.databases.default(to: .psql)
        app.passwords.use(.plaintext)
        try app.autoMigrate().wait()
        return app
    }
    
    override open func setUpWithError() throws {
        self.app = try self.createTestApp()
    }
    
    override open func tearDownWithError() throws {
        app.shutdown()
    }
    
    func getApiToken(_ user: UserLogin, _ app: Application) throws -> User.Token.Detail {
        var token: User.Token.Detail?
//        try app
//            .describe("Test login")
//            .post("/api/sign-in/")
//            .body(user)
//            .expect(User.Token.Detail.self) { content in
//                XCTAssert(!content.value.isEmpty)
//                token = content
//            }
//            .test()

        try app.test(.POST, "/api/sign-in/", beforeRequest: { req in
            try req.content.encode(user)
        }, afterResponse: { res in
            XCTAssertContent(User.Token.Detail.self, res) { content in
                token = content
            }
        })
        guard let result = token else {
            XCTFail("Login failed")
            throw Abort(.unauthorized)
        }
        return result
    }
    
    func getRootApiToken(_ app: Application) throws -> User.Token.Detail {
        try getApiToken(.init(email: "root@localhost.com", password: "ChangeMe1"), app)
    }
}

