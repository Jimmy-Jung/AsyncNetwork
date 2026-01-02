import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncNetworkDocKit",
    targets: [
        .target(
            name: "AsyncNetworkDocKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.asyncnetwork.AsyncNetworkDocKit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "AsyncNetwork")
            ],
            settings: .frameworkSettings()
        ),
        .target(
            name: "AsyncNetworkDocKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.asyncnetwork.AsyncNetworkDocKitTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "AsyncNetworkDocKit")
            ]
        )
    ]
)
