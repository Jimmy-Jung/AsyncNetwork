import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "NetworkKitExample",
    targets: [
        .target(
            name: "NetworkKitExample",
            destinations: .iOS,
            product: .app,
            bundleId: "net.megastudy.NetworkKitExample",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:],
                ]
            ),
            sources: ["NetworkKitExample/Sources/**"],
            resources: ["NetworkKitExample/Resources/**"],
            dependencies: [
                .external(name: "NetworkKit"),
                .external(name: "AsyncViewModel"),
                .external(name: "TraceKit"),
            ],
            settings: .appSettings()
        ),
        .target(
            name: "NetworkKitExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "net.megastudy.NetworkKitExample.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["NetworkKitExample/Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "NetworkKitExample"),
            ],
            settings: .targetSettings()
        ),
    ],
    schemes: [
        .appScheme(
            name: "NetworkKitExample",
            testTargets: [
                .testableTarget(target: .target("NetworkKitExampleTests")),
            ]
        ),
    ]
)
