// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "NetworkKit": .framework,
            "AsyncViewModel": .framework,
            "TraceKit": .framework,
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:]),
            ]
        )
    )
#endif

let package = Package(
    name: "NetworkKitExample",
    dependencies: [
        // NetworkKit (Local Development)
        .package(path: "../../../"),

        // AsyncViewModel (GitHub)
        .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel", from: "1.2.0"),

        // TraceKit (Logging)
        .package(url: "https://github.com/Jimmy-Jung/TraceKit.git", from: "1.1.2"),
    ]
)
