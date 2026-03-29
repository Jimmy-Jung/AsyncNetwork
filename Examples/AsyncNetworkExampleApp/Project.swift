//
//  Project.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import ProjectDescription

let project = Project(
    name: "AsyncNetworkExampleApp",
    organizationName: "com.asyncnetwork",
    targets: [
        .target(
            name: "AsyncNetworkExampleApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.asyncnetwork.example.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "CFBundleDisplayName": "AsyncNetwork Example",
                    "UILaunchScreen": [:],
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [:]
                    ]
                ]
            ),
            sources: [
                "Sources/**"
            ],
            dependencies: [
                .external(name: "AsyncNetwork")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "",
                    "CODE_SIGN_STYLE": "Automatic",
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "TARGETED_DEVICE_FAMILY": "1,2"
                ]
            )
        ),
        .target(
            name: "AsyncNetworkExampleAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.asyncnetwork.example.app.tests",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "AsyncNetworkExampleApp"),
                .external(name: "AsyncNetwork")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "AsyncNetworkExampleApp",
            shared: true,
            buildAction: .buildAction(targets: ["AsyncNetworkExampleApp"]),
            testAction: .targets([
                .testableTarget(target: "AsyncNetworkExampleAppTests")
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
