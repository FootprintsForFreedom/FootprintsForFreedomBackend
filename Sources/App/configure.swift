import Fluent
import FluentPostgresDriver
import Vapor
import SwiftSMTPVapor
import QueuesRedisDriver
import VaporSecurityHeaders
@_exported import AppApi
@_exported import CollectionConcurrencyKit

/// Configures the application.
/// - Parameter app: The application to configure.
public func configure(_ app: Application) throws {
    // Reset the middlewares since the security headers middleware should come first
    app.middleware = Middlewares()
    // Add security headers
    // This tells the browser to force HTTPS for a year, and for every subdomain as well.
    let strictTransportSecurityConfig = StrictTransportSecurityConfiguration(maxAge: 31536000, includeSubdomains: true, preload: true)
    // The no-referrer value instructs the browser to never send the referer header with requests that are made
    let referrerPolicyConfig = ReferrerPolicyConfiguration(.noReferrer)
    
    let securityHeaders = SecurityHeadersFactory
        .api()
        .with(strictTransportSecurity: strictTransportSecurityConfig)
        .with(referrerPolicy: referrerPolicyConfig)
    app.middleware.use(securityHeaders.build())
    
    // Add the default middlewares
    app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
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
    
    // Initialize SwiftSMTP
    app.swiftSMTP.initialize(with: .fromEnvironment())
    
    // Initialize MMDB
    try app.mmdb.loadMMDB()
    app.queues.schedule(ReloadMMDBJob())
        .hourly()
        .at(5)
    
    // setup modules
    let modules: [ModuleInterface] = [
        StatusModule(),
        UserModule(),
        LanguageModule(),
        StaticContentModule(),
        WaypointModule(),
        MediaModule(),
        TagModule(),
        ApiModule(),
        RedirectModule()
    ]
    for module in modules {
        try module.boot(app)
    }
    for module in modules {
        try module.setUp(app)
    }
    
    // use automatic database migration
    if app.environment != .production {
        try app.autoMigrate().wait()
    }
}
