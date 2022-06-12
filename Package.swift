// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Backend",
    platforms: [
        .macOS(.v12)
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
        .package(url: "https://github.com/binarybirds/liquid", from: "1.3.0"),
        .package(url: "https://github.com/binarybirds/liquid-local-driver", from: "1.3.0"),
        .package(url: "https://github.com/binarybirds/spec", from: "1.2.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "diff_match_patch"),
        .target(name: "DiffMatchPatch", dependencies: [
            .target(name: "diff_match_patch"),
        ]),
        .target(name: "AppApi", dependencies: [
            .target(name: "DiffMatchPatch")
        ]),
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "SwiftSMTPVapor", package: "swift-smtp"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Liquid", package: "liquid"),
                .product(name: "LiquidLocalDriver", package: "liquid-local-driver"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
                
                .target(name: "DiffMatchPatch"),
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
