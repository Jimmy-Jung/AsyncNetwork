import ProjectDescription

// MARK: - Settings Templates

public extension Settings {
    /// 기본 타겟 설정
    static func targetSettings() -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "ENABLE_TESTABILITY": "YES",
            ],
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release"),
            ],
            defaultSettings: .recommended
        )
    }

    /// 앱 타겟 설정
    static func appSettings() -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "DEVELOPMENT_TEAM": "",
                "CODE_SIGN_STYLE": "Automatic",
                "ENABLE_TESTABILITY": "YES",
            ],
            configurations: [
                .debug(
                    name: "Debug",
                    settings: [
                        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
                        "GCC_OPTIMIZATION_LEVEL": "0",
                    ]
                ),
                .release(
                    name: "Release",
                    settings: [
                        "SWIFT_OPTIMIZATION_LEVEL": "-O",
                        "SWIFT_COMPILATION_MODE": "wholemodule",
                    ]
                ),
            ],
            defaultSettings: .recommended
        )
    }
}
