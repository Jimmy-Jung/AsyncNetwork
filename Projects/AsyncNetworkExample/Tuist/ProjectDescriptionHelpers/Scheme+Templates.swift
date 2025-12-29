import ProjectDescription

// MARK: - Scheme Templates

public extension Scheme {
    /// 앱 스킴 생성 (빌드, 테스트, 실행 포함)
    static func appScheme(
        name: String,
        testTargets: [TestableTarget] = []
    ) -> Scheme {
        return Scheme.scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(
                targets: [.target(name)],
                preActions: [],
                postActions: []
            ),
            testAction: .targets(
                testTargets,
                configuration: .debug,
                options: .options(
                    coverage: true,
                    codeCoverageTargets: [.target(name)]
                )
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: .target(name)
            ),
            archiveAction: .archiveAction(
                configuration: .release
            ),
            profileAction: .profileAction(
                configuration: .release,
                executable: .target(name)
            ),
            analyzeAction: .analyzeAction(
                configuration: .debug
            )
        )
    }
}
