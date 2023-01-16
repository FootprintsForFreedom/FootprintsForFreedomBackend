// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Backend",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "AppApi", targets: ["AppApi"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver", from: "4.1.0"),
        .package(url: "https://github.com/sersoft-gmbh/swift-smtp.git", from: "2.0.0"),
        .package(url: "https://github.com/binarybirds/spec", from: "1.2.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
        .package(url: "https://github.com/niklhut/SwiftDiff.git", branch: "master"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/brokenhandsio/VaporSecurityHeaders.git", from: "4.0.0"),
        .package(url: "https://github.com/niklhut/elasticsearch-nio-client.git", branch: "custom"),
        .package(url: "https://github.com/SwiftPackageRepository/ISO639.swift.git", branch: "master"),
        .package(url: "https://github.com/niklhut/swift-mmdb.git", branch: "city"),
    ],
    targets: [
        .target(name: "AppApi", dependencies: [
            .product(name: "SwiftDiff", package: "SwiftDiff"),
        ]),
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "SwiftSMTPVapor", package: "swift-smtp"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
                .product(name: "SwiftDiff", package: "SwiftDiff"),
                .product(name: "SwiftGD", package: "SwiftGD"),
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "VaporSecurityHeaders", package: "VaporSecurityHeaders"),
                .product(name: "ElasticsearchNIOClient", package: "elasticsearch-nio-client"),
                .product(name: "ISO639", package: "ISO639.swift"),
                .product(name: "MMDB", package: "swift-mmdb"),
                .target(name: "AppApi")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "Spec", package: "spec"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            resources: [
                .process("Resources")
            ]),
        .testTarget(name: "AppApiTests", dependencies: [
            .target(name: "AppApi"),
        ])
    ]
)
