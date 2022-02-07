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
    
    func createTestApp() async throws -> Application {
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
        try await app.autoMigrate()
        return app
    }
    
    open override func setUp() async throws {
        app = try await createTestApp()
    }
    
    open override func tearDown() async throws {
        app.shutdown()
    }
    
    func getApiToken(_ user: UserLogin, _ app: Application) throws -> User.Token.Detail {
        var token: User.Token.Detail?
        
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
    
    func getTokenFromOtherUser() async throws -> String {
        let newUserPassword = "password"
        let newUser = UserAccountModel(name: "Test User", email: "nonadmin-test-user@example.com", school: nil, password: try app.password.hash(newUserPassword), verified: false, role: .user)
        try await newUser.create(on: app.db)

        let token = try newUser.generateToken()
        try await token.create(on: app.db)
        return token.value
    }
    
    func getTokenFromOtherModeratorUser() async throws -> String {
        let newAdminUserPassword = "password123"
        let newAdminUser = UserAccountModel(name: "Test Admin User", email: "test-admin-user@example.com", school: nil, password: try app.password.hash(newAdminUserPassword), verified: false, role: .moderator)
        try await newAdminUser.create(on: app.db)

        let adminToken = try newAdminUser.generateToken()
        try await adminToken.create(on: app.db)
        return adminToken.value
    }
    
}

open class AppTestCaseWithToken: AppTestCase {
    var token: String!

    override open func setUp() async throws {
        app = try await createTestApp()
        token = try await getTokenFromOtherUser()
    }
}

open class AppTestCaseWithAdminToken: AppTestCase {
    var adminToken: String!

    override open func setUp() async throws {
        app = try await createTestApp()
        adminToken = try await getTokenFromOtherModeratorUser()
    }
}

open class AppTestCaseWithAdminAndNormalToken: AppTestCase {
    var token: String!
    var adminToken: String!

    override open func setUp() async throws {
        app = try await self.createTestApp()

        token = try await getTokenFromOtherUser()
        adminToken = try await getTokenFromOtherModeratorUser()
    }
}
