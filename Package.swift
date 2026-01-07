// swift-tools-version: 6.0
// Package.swift
// AsyncNetwork

import CompilerPluginSupport
import PackageDescription

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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        // MARK: - Core Network Library

        // Projects/AsyncNetwork/Sources 폴더 전체를 사용하되,
        // Umbrella 모듈인 AsyncNetwork 폴더는 제외
        // (Core 기능만 포함: Models, Client, Service, Processing 등)
        .target(
            name: "AsyncNetworkCore",
            dependencies: [],
            path: "Projects/AsyncNetwork/Sources",
            exclude: ["AsyncNetwork"]
        ),

        // MARK: - Umbrella Target (Core + Macros)

        // AsyncNetworkCore와 AsyncNetworkMacros를 통합한 단일 import 모듈
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

        // MARK: - Macro Public Interface

        .target(
            name: "AsyncNetworkMacros",
            dependencies: [
                "AsyncNetworkMacrosImpl",
                "AsyncNetworkCore"
            ],
            path: "Projects/AsyncNetworkMacros/Sources/AsyncNetworkMacros"
        ),

        // MARK: - Macro Implementation (Compiler Plugin)

        .macro(
            name: "AsyncNetworkMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Projects/AsyncNetworkMacros/Sources/AsyncNetworkMacrosImpl"
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
        )
    ]
)
