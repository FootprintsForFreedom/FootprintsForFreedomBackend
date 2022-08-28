import Fluent
import FluentPostgresDriver
import Vapor
import SwiftSMTPVapor
import QueuesRedisDriver
@_exported import AppApi
@_exported import CollectionConcurrencyKit

/// Configures the application.
/// - Parameter app: The application to configure.
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(.postgres(
        hostname: Environment.dbHost,
        port: Environment.dbPort.flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.pgUser,
        password: Environment.pgPassword,
        database: Environment.pgDbName
    ), as: .psql)
    
    // setup queues
    try app.queues.use(.redis(url: Environment.redisUrl))
    
    app.queues.schedule(CleanupEmptyRepositoriesJob())
        .weekly()
        .on(.tuesday)
        .at(2, 0)
    
    app.queues.schedule(CleanupOldVerifiedModelsJob())
        .weekly()
        .on(.wednesday)
        .at(2, 0)
    
    app.queues.schedule(CleanupSoftDeletedModelsJob())
        .weekly()
        .on(.thursday)
        .at(2, 0)
    
    /// Initialize SwiftSMTP
    app.swiftSMTP.initialize(with: .fromEnvironment())
    
    /// setup modules
    let modules: [ModuleInterface] = [
        StatusModule(),
        UserModule(),
        LanguageModule(),
        StaticContentModule(),
        WaypointModule(),
        MediaModule(),
        TagModule(),
        ApiModule(),
    ]
    for module in modules {
        try module.boot(app)
    }
    for module in modules {
        try module.setUp(app)
    }
    
    /// use automatic database migration
    if app.environment != .production {
        try app.autoMigrate().wait()
    }
}
