// swift-tools-version: 6.0
//
//  Package.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "AsyncNetwork": .framework
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:])
            ]
        )
    )
#endif

let package = Package(
    name: "AsyncNetworkExampleApp",
    dependencies: [
        .package(path: "../../../")
    ]
)
