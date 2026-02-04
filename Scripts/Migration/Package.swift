// swift-tools-version: 6.0
// Migration Tool Package
// SwiftSyntax 기반 정교한 마이그레이션 도구

import PackageDescription

let package = Package(
    name: "AsyncNetworkMigrationTool",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "migrate-async-network",
            targets: ["MigrationTool"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MigrationTool",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources"
        )
    ]
)
