// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            // SwiftSyntax main products
            "SwiftSyntax": .framework,
            "SwiftSyntaxMacros": .framework,
            "SwiftCompilerPlugin": .framework,
            "SwiftSyntaxMacrosTestSupport": .framework,

            // SwiftSyntax internal dependencies - dynamic으로 설정하여 중복 링크 방지
            "SwiftBasicFormat": .framework,
            "SwiftDiagnostics": .framework,
            "SwiftOperators": .framework,
            "SwiftParser": .framework,
            "SwiftParserDiagnostics": .framework,
            "SwiftSyntaxBuilder": .framework,
            "SwiftSyntaxMacroExpansion": .framework,
            "_SwiftSyntaxCShims": .framework
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
        // Swift Syntax (for Macros)
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0")
    ]
)
