// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "AsyncNetworkCore": .framework,
            "AsyncNetwork": .framework,
            "AsyncNetworkMacros": .framework
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release")
            ]
        )
    )
#endif

let package = Package(
    name: "AsyncNetworkDependencies",
    dependencies: [
        // AsyncNetwork (Local Package)
        .package(path: ".."),

        // Swift Syntax (for Macros)
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0")
    ]
)
