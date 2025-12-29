import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncNetworkExample",
    targets: [
        .target(
            name: "AsyncNetworkExample",
            destinations: .iOS,
            product: .app,
            bundleId: "net.megastudy.AsyncNetworkExample",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:],
                ]
            ),
            sources: ["AsyncNetworkExample/Sources/**"],
            resources: ["AsyncNetworkExample/Resources/**"],
            dependencies: [
                .external(name: "AsyncNetwork"),
                .external(name: "AsyncViewModel"),
                .external(name: "TraceKit"),
            ],
            settings: .appSettings()
        ),
        .target(
            name: "AsyncNetworkExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "net.megastudy.AsyncNetworkExample.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["AsyncNetworkExample/Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "AsyncNetworkExample"),
            ],
            settings: .targetSettings()
        ),
    ],
    schemes: [
        .appScheme(
            name: "AsyncNetworkExample",
            testTargets: [
                .testableTarget(target: .target("AsyncNetworkExampleTests")),
            ]
        ),
    ]
)
