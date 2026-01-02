// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // 외부 의존성 타입 설정
        // .framework: 동적 프레임워크 (개발 시 빠른 빌드)
        // .staticFramework: 정적 프레임워크 (릴리즈 시 최적화)
        productTypes: [
            "AsyncNetwork": .framework,  // 로컬 SPM 패키지 (Core + Macros 통합)
            "AsyncNetworkCore": .framework,
            "AsyncNetworkMacros": .framework,
            "AsyncNetworkDocKit": .framework,  // 문서화 UI 프레임워크
        ],
        // 매크로 타겟은 자동으로 처리되므로 baseSettings에서 제외
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:])
            ]
        )
    )
#endif

let package = Package(
    name: "AsyncNetworkDocKitExample",
    dependencies: [
        // AsyncNetwork (Local Development - includes DocKit)
        .package(path: "../"),
    ]
)
