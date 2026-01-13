// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "AsyncNetwork": .framework,
            "AsyncViewModel": .framework,
            "TraceKit": .framework
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:])
            ]
        )
    )
#endif

let package = Package(
    name: "AsyncNetworkSampleApp",
    dependencies: [
        // AsyncNetwork (Local)
        .package(path: "../"),
        // AsyncViewModel (Remote)
        .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel.git", from: "1.2.0"),
        // TraceKit (Remote)
        .package(url: "https://github.com/Jimmy-Jung/TraceKit", from: "1.1.1")
    ]
)
