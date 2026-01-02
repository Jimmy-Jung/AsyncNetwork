import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncNetworkDocKitExample",
    targets: [
        .target(
            name: "AsyncNetworkDocKitExample",
            destinations: .iOS,
            product: .app,
            bundleId: "com.asyncnetwork.AsyncNetworkDocKitExample",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:]
                ]
            ),
            sources: ["AsyncNetworkDocKitExample/Sources/**"],
            resources: ["AsyncNetworkDocKitExample/Resources/**"],
            dependencies: [
                // AsyncNetworkDocKit를 import하면 AsyncNetwork와 AsyncNetworkMacros도 자동으로 사용 가능
                .project(target: "AsyncNetworkDocKit", path: "../AsyncNetworkDocKit")
            ],
            settings: .appSettings()
        )
    ],
    schemes: [
        .appScheme(
            name: "AsyncNetworkDocKitExample",
            testTargets: []
        )
    ]
)
