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
                    "UILaunchScreen": [:],
                ]
            ),
            sources: ["AsyncNetworkDocKitExample/Sources/**"],
            resources: ["AsyncNetworkDocKitExample/Resources/**"],
            dependencies: [
                // AsyncNetworkDocKit (로컬 SPM 패키지 - Tuist/Package.swift 참조)
                .external(name: "AsyncNetworkDocKit"),
                // AsyncNetwork (로컬 SPM 패키지 - Tuist/Package.swift 참조)
                .external(name: "AsyncNetwork"),
            ],
            settings: .appSettings()
        ),
    ],
    schemes: [
        .appScheme(
            name: "AsyncNetworkDocKitExample",
            testTargets: []
        ),
    ]
)
