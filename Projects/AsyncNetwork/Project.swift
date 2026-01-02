import ProjectDescription

let project = Project(
    name: "AsyncNetwork",
    targets: [
        // MARK: - AsyncNetworkCore (Core Library)

        .target(
            name: "AsyncNetworkCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.asyncnetwork.AsyncNetworkCore",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: [
                "Sources/Client/**",
                "Sources/Configuration/**",
                "Sources/Errors/**",
                "Sources/Interceptors/**",
                "Sources/Models/**",
                "Sources/Processing/**",
                "Sources/PropertyWrappers/**",
                "Sources/Protocols/**",
                "Sources/Service/**",
                "Sources/Utilities/**"
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "ENABLE_TESTING_SEARCH_PATHS": "YES",
                    "SUPPORTED_PLATFORMS":
                        "iphoneos iphonesimulator macosx appletvos appletvsimulator watchos watchsimulator"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        ),

        // MARK: - AsyncNetworkMacros (Public Interface)

        .target(
            name: "AsyncNetworkMacros",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.asyncnetwork.AsyncNetworkMacros",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: [
                "../AsyncNetworkMacros/Sources/AsyncNetworkMacros/**"
            ],
            dependencies: [
                .target(name: "AsyncNetworkCore"),
                .external(name: "SwiftSyntax"),
                .external(name: "SwiftSyntaxMacros"),
                .external(name: "SwiftCompilerPlugin")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "SUPPORTED_PLATFORMS":
                        "iphoneos iphonesimulator macosx appletvos appletvsimulator watchos watchsimulator"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        ),

        // MARK: - AsyncNetwork (Umbrella Framework)

        .target(
            name: "AsyncNetwork",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.asyncnetwork.AsyncNetwork",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: [
                "Sources/AsyncNetwork/**"
            ],
            dependencies: [
                .target(name: "AsyncNetworkCore"),
                .target(name: "AsyncNetworkMacros")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "SUPPORTED_PLATFORMS":
                        "iphoneos iphonesimulator macosx appletvos appletvsimulator watchos watchsimulator"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        ),

        // MARK: - AsyncNetworkTests

        .target(
            name: "AsyncNetworkTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.asyncnetwork.AsyncNetworkTests",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "AsyncNetworkCore"),
                .target(name: "AsyncNetwork")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "ENABLE_TESTING_SEARCH_PATHS": "YES"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        ),

        // MARK: - AsyncNetworkMacrosTests (iOS only - macOS macro tests handled by SPM)

        .target(
            name: "AsyncNetworkMacrosTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.asyncnetwork.AsyncNetworkMacrosTests",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: [
                "../AsyncNetworkMacros/Tests/**"
            ],
            dependencies: [
                .target(name: "AsyncNetworkMacros"),
                .external(name: "SwiftSyntaxMacrosTestSupport")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "ENABLE_TESTING_SEARCH_PATHS": "YES"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        )
    ],
    schemes: [
        // AsyncNetwork Scheme (Full)
        .scheme(
            name: "AsyncNetwork",
            shared: true,
            buildAction: .buildAction(targets: [
                "AsyncNetworkCore",
                "AsyncNetworkMacros",
                "AsyncNetwork"
            ]),
            testAction: .targets(
                [
                    .testableTarget(target: "AsyncNetworkTests"),
                    .testableTarget(target: "AsyncNetworkMacrosTests")
                ],
                configuration: "Debug",
                options: .options(
                    coverage: true,
                    codeCoverageTargets: ["AsyncNetworkCore"]
                )
            ),
            runAction: nil,
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),

        // AsyncNetworkMacros Scheme
        .scheme(
            name: "AsyncNetworkMacros",
            shared: true,
            buildAction: .buildAction(targets: ["AsyncNetworkMacros"]),
            testAction: .targets(
                [.testableTarget(target: "AsyncNetworkMacrosTests")],
                configuration: "Debug",
                options: .options(
                    coverage: true,
                    codeCoverageTargets: ["AsyncNetworkMacros"]
                )
            ),
            runAction: nil,
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
