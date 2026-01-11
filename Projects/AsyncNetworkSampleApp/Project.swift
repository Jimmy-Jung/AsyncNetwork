//
//  Project.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import ProjectDescription

let project = Project(
    name: "AsyncNetworkSampleApp",
    organizationName: "com.asyncnetwork",
    targets: [
        .target(
            name: "AsyncNetworkSampleApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.asyncnetwork.sample",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:],
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [
                            "UIWindowSceneSessionRoleApplication": [
                                [
                                    "UISceneConfigurationName": "Default Configuration",
                                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                                ]
                            ]
                        ]
                    ]
                ]
            ),
            sources: [
                "Sources/**"
            ],
            resources: [
                "Resources/**"
            ],
                    dependencies: [
                        .external(name: "AsyncNetwork"),
                        .external(name: "AsyncViewModel"),
                        .external(name: "TraceKit")
                    ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "",
                    "CODE_SIGN_STYLE": "Automatic",
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "DISABLE_DIAMOND_PROBLEM_DIAGNOSTIC": "YES"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        ),
        .target(
            name: "AsyncNetworkSampleAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.asyncnetwork.sample.tests",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "AsyncNetworkSampleApp"),
                .external(name: "AsyncNetwork"),
                .external(name: "AsyncViewModel"),
                .external(name: "TraceKit")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "AsyncNetworkSampleApp",
            shared: true,
            buildAction: .buildAction(targets: ["AsyncNetworkSampleApp"]),
            testAction: .targets([
                .testableTarget(target: "AsyncNetworkSampleAppTests")
            ]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)

