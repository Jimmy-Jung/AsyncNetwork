// swift-tools-version: 6.0
// Package.swift
// AsyncNetwork

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AsyncNetwork",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Core library
        .library(
            name: "AsyncNetworkCore",
            targets: ["AsyncNetworkCore"]
        ),
        // Umbrella library (Core + Macros 통합)
        .library(
            name: "AsyncNetwork",
            targets: ["AsyncNetwork"]
        ),
        // Macros library
        .library(
            name: "AsyncNetworkMacros",
            targets: ["AsyncNetworkMacros"]
        ),
        .library(
            name: "AsyncNetworkDocKit",
            targets: ["AsyncNetworkDocKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/JosephDuffy/AsyncViewModel.git", from: "0.2.1")
    ],
    targets: [
        // MARK: - Core Network Library
        .target(
            name: "AsyncNetworkCore",
            dependencies: [],
            path: "Projects/AsyncNetwork/Sources",
            exclude: ["AsyncNetwork"]
        ),

        // MARK: - Umbrella Target (Core + Macros)
        .target(
            name: "AsyncNetwork",
            dependencies: [
                "AsyncNetworkCore",
                "AsyncNetworkMacros"
            ],
            path: "Projects/AsyncNetwork/Sources/AsyncNetwork"
        ),

        .testTarget(
            name: "AsyncNetworkTests",
            dependencies: ["AsyncNetworkCore"],
            path: "Projects/AsyncNetwork/Tests"
        ),

        // MARK: - Macro Implementation
        .macro(
            name: "AsyncNetworkMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Projects/AsyncNetworkMacros/Sources/AsyncNetworkMacrosImpl"
        ),

        // MARK: - Macro Public Interface
        .target(
            name: "AsyncNetworkMacros",
            dependencies: [
                "AsyncNetworkMacrosImpl",
                "AsyncNetworkCore"
            ],
            path: "Projects/AsyncNetworkMacros/Sources/AsyncNetworkMacros"
        ),

        // MARK: - Macro Tests
        .testTarget(
            name: "AsyncNetworkMacrosTests",
            dependencies: [
                "AsyncNetworkMacros",
                "AsyncNetworkMacrosImpl",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Projects/AsyncNetworkMacros/Tests"
        ),

        // MARK: - Documentation Kit (iOS only - SwiftUI App features)
        .target(
            name: "AsyncNetworkDocKit",
            dependencies: [
                "AsyncNetworkCore",
                "AsyncNetworkMacros"
            ],
            path: "Projects/AsyncNetworkDocKit/Sources",
            swiftSettings: [
                .define("DOCKIT_IOS_ONLY")
            ]
        )
    ]
)
