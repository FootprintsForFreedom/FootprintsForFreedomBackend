//
//  MigrationTests.swift
//  
//
//  Created by niklhut on 11.06.22.
//

@testable import App
import XCTVapor
import FluentPostgresDriver

final class MigrationTests: XCTestCase {
    func testMigrateAndTearDown() async throws {
        let app = Application(.testing)
        
        try configure(app)
        app.databases.reinitialize()
        app.databases.use(.postgres(
            hostname: Environment.dbHost,
            port: Environment.dbPort.flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.pgUser,
            password: Environment.pgPassword,
            database: Environment.pgTestDbName
        ), as: .psql)
        app.databases.default(to: .psql)
        app.passwords.use(.plaintext)
        
        try await app.autoMigrate()
        try await app.autoRevert()
        app.shutdown()
    }
}
