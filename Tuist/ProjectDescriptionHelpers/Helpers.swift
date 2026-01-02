import ProjectDescription

public extension Target {
    static func appTarget(
        name: String,
        bundleId: String,
        deploymentTarget: String = "17.0",
        sources: SourceFilesList = ["Sources/**"],
        resources: ResourceFileElements? = ["Resources/**"],
        dependencies: [TargetDependency] = []
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .app,
            bundleId: bundleId,
            deploymentTargets: .iOS(deploymentTarget),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchScreen": [:]
                ]
            ),
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
    }

    static func frameworkTarget(
        name: String,
        bundleId: String,
        deploymentTarget: String = "17.0",
        sources: SourceFilesList = ["Sources/**"],
        dependencies: [TargetDependency] = []
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .framework,
            bundleId: bundleId,
            deploymentTargets: .iOS(deploymentTarget),
            infoPlist: .default,
            sources: sources,
            dependencies: dependencies
        )
    }
}

public extension Settings {
    static func appSettings() -> Settings {
        .settings(
            base: [
                "DEVELOPMENT_TEAM": "",
                "CODE_SIGN_STYLE": "Automatic"
            ],
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release")
            ]
        )
    }

    static func frameworkSettings() -> Settings {
        .settings(
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release")
            ]
        )
    }
}

public extension Scheme {
    static func appScheme(
        name: String,
        testTargets: [TestableTarget]
    ) -> Scheme {
        .scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: ["\(name)"]),
            testAction: .targets(testTargets),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    }
}
