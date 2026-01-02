import ProjectDescription

let project = Project(
    name: "AsyncNetworkMacros",
    targets: [
        // Macro Implementation (macOS only, for compile-time execution)
        .target(
            name: "AsyncNetworkMacrosImpl",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.asyncnetwork.AsyncNetworkMacrosImpl",
            deploymentTargets: .macOS("10.15"),
            infoPlist: .default,
            sources: ["Sources/AsyncNetworkMacrosImpl/**"],
            dependencies: [
                .external(name: "SwiftSyntaxMacros"),
                .external(name: "SwiftCompilerPlugin")
            ]
        ),

        // Public Macro Interface (iOS, references macOS impl)
        .target(
            name: "AsyncNetworkMacros",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.asyncnetwork.AsyncNetworkMacros",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: ["Sources/AsyncNetworkMacros/**"],
            dependencies: [
                .external(name: "AsyncNetworkCore")
            ]
        ),

        // Tests (macOS only)
        .target(
            name: "AsyncNetworkMacrosTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.asyncnetwork.AsyncNetworkMacrosTests",
            deploymentTargets: .macOS("10.15"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "AsyncNetworkMacrosImpl"),
                .external(name: "SwiftSyntaxMacrosTestSupport")
            ]
        )
    ]
)
