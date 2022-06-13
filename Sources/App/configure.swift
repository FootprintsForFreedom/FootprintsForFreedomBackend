import Fluent
import FluentPostgresDriver
import Vapor
import Liquid
import SwiftSMTPVapor
import QueuesRedisDriver
@_exported import AppApi
@_exported import CollectionConcurrencyKit

// configures your application
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
    try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
    
    app.queues.schedule(CleanupEmptyRepositoriesJob())
        .weekly()
        .on(.tuesday)
        .at(2, 0)
    
    app.queues.schedule(CleanupSoftDeletedModelsJob())
        .weekly()
        .on(.wednesday)
        .at(2, 0)
    
    /// set the max file upload limit
//    app.routes.defaultMaxBodySize = "10mb"
    
    /// use the Public directory to serve public files
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    /// extend paths to always contain a trailing slash
//    app.middleware.use(ExtendPathMiddleware())
    
    /// setup sessions
//    app.sessions.use(.fluent)
//    app.migrations.add(SessionRecord.migration)
//    app.middleware.use(app.sessions.middleware)
    
    /// Initialize SwiftSMTP
    app.swiftSMTP.initialize(with: .fromEnvironment())
    
    /// setup modules
    let modules: [ModuleInterface] = [
//        WebModule(),
        StatusModule(),
        UserModule(),
        LanguageModule(),
        StaticContentModule(),
        WaypointModule(),
        MediaModule(),
        TagModule(),
//        AdminModule(),
        ApiModule(),
//        BlogModule(),
    ]
    for module in modules {
        try module.boot(app)
    }
    for module in modules {
        try module.setUp(app)
    }
    
    /// use automatic database migration
    try app.autoMigrate().wait()
}
