import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init(
        [
            .local(path: "../"), // AsyncNetwork
            .remote(url: "https://github.com/Jimmy-Jung/AsyncViewModel.git", requirement: .exact("1.2.0")) // AsyncViewModel
        ],
        productTypes: [
            "AsyncNetwork": .framework,
            "AsyncViewModel": .framework
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release")
            ]
        )
    ),
    platforms: [.iOS]
)
