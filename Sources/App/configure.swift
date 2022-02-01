import Fluent
import FluentPostgresDriver
import Vapor
import Liquid
import LiquidLocalDriver
@_exported import AppApi

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "nh",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "digital_traces"
    ), as: .psql)
    
    /// setup Liquid using the local file storage driver
    app.fileStorages.use(.local(publicUrl: "http://localhost:8080",
                                publicPath: app.directory.publicDirectory,
                                workDirectory: "assets"), as: .local)

    /// set the max file upload limit
    app.routes.defaultMaxBodySize = "10mb"
    
    /// use the Public directory to serve public files
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    /// extend paths to always contain a trailing slash
//    app.middleware.use(ExtendPathMiddleware())
    
    /// setup sessions
//    app.sessions.use(.fluent)
//    app.migrations.add(SessionRecord.migration)
//    app.middleware.use(app.sessions.middleware)

    
    /// setup modules
    let modules: [ModuleInterface] = [
//        WebModule(),
        UserModule(),
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
