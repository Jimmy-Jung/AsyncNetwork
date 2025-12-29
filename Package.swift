// swift-tools-version: 6.0
// Package.swift
// NetworkKit

import PackageDescription

let package = Package(
    name: "NetworkKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "NetworkKit",
            targets: ["NetworkKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NetworkKit",
            dependencies: [],
            path: "Projects/NetworkKit/Sources"
        ),
        .testTarget(
            name: "NetworkKitTests",
            dependencies: ["NetworkKit"],
            path: "Projects/NetworkKit/Tests"
        ),
    ]
)
