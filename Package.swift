// swift-tools-version: 6.0
// Package.swift
// AsyncNetwork

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
        .library(
            name: "AsyncNetwork",
            targets: ["AsyncNetwork"]
        ),
        .library(
            name: "AsyncNetworkCore",
            targets: ["AsyncNetworkCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AsyncNetworkCore",
            dependencies: [],
            path: "Projects/AsyncNetwork/Sources",
            exclude: ["AsyncNetwork"]
        ),
        .target(
            name: "AsyncNetwork",
            dependencies: [
                "AsyncNetworkCore"
            ],
            path: "Projects/AsyncNetwork/Sources/AsyncNetwork"
        ),
        .testTarget(
            name: "AsyncNetworkTests",
            dependencies: [
                "AsyncNetworkCore",
                "AsyncNetwork"
            ],
            path: "Projects/AsyncNetwork/Tests",
            exclude: ["README.md"]
        )
    ]
)
