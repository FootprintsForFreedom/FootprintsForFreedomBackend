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
//        app.databases.use(.sqlite(.memory), as: .sqlite)
//        app.databases.default(to: .sqlite)
        app.databases.use(.postgres(
            hostname: Environment.dbHost,
            username: Environment.pgUser,
            password: Environment.pgPassword,
            database: Environment.pgTestDbName
        ), as: .psql)
        app.databases.default(to: .psql)
        app.passwords.use(.plaintext)
        try await app.autoMigrate()
        return app
    }
    
    open override func setUp() async throws {
        app = try await createTestApp()
    }
    
    open override func tearDown() async throws {
        if try await WaypointRepositoryModel.query(on: app.db).count() > 50 {
            try await app.autoRevert()
        }
        app.shutdown()
    }
    
    func getApiToken(_ user: UserLogin) throws -> User.Token.Detail {
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
    
    func getUser(role: User.Role, verified: Bool = false) async throws -> UserAccountModel {
        let newUserPassword = "password"
        let newUser = UserAccountModel(name: "Test User", email: "test-user\(UUID())@example.com", school: nil, password: try app.password.hash(newUserPassword), verified: verified, role: role)
        try await newUser.create(on: app.db)
        return newUser
    }
    
    func getToken(for userRole: User.Role, verified: Bool = false) async throws -> String {
        let newUser = try await getUser(role: userRole, verified: verified)
        let token = try newUser.generateToken()
        try await token.create(on: app.db)
        return token.value
    }
    
    func data(for resource: String, withExtension fileExtension: String) throws -> Data {
        let fileURL = Bundle.module.url(forResource: resource, withExtension: fileExtension)!
        let data = try Data(contentsOf: fileURL)
        return data
    }
}

// TODO: remove?
open class AppTestCaseWithModeratorToken: AppTestCase {
    var moderatorToken: String!
    
    override open func setUp() async throws {
        app = try await createTestApp()
        moderatorToken = try await getToken(for: .moderator)
    }
}

open class AppTestCaseWithModeratorAndNormalToken: AppTestCase {
    var token: String!
    var moderatorToken: String!
    
    override open func setUp() async throws {
        app = try await self.createTestApp()
        
        token = try await getToken(for: .user)
        moderatorToken = try await getToken(for: .moderator)
    }
}
