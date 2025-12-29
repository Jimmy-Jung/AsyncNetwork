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
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "AsyncNetwork",
            targets: ["AsyncNetwork"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsyncNetwork",
            dependencies: [],
            path: "Projects/AsyncNetwork/Sources"
        ),
        .testTarget(
            name: "AsyncNetworkTests",
            dependencies: ["AsyncNetwork"],
            path: "Projects/AsyncNetwork/Tests"
        ),
    ]
)
