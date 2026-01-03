#!/usr/bin/env swift

//
//  CreateDocKitExample.swift
//  AsyncNetwork
//
//  DocKitExample 앱을 자동으로 생성하는 스크립트
//
//  Created by jimmy on 2026-01-03.
//

import Foundation

// MARK: - Models

enum SourcePathType {
    case tuistModule(path: String, moduleName: String) // Tuist 모듈 (Project.swift 존재)
    case folder(path: String) // 일반 폴더
}

struct DocKitExampleConfig {
    let appName: String
    let bundleIdPrefix: String
    let sourcePaths: [String]
    let sourcePathTypes: [SourcePathType] // ✨ 경로 타입 정보
    let outputPath: String
    let scriptsPath: String
}

// MARK: - File Generator

struct FileGenerator {
    let config: DocKitExampleConfig

    // MARK: - Project.swift 생성

    func generateProjectSwift() -> String {
        // 소스 경로를 빌드 스크립트 내에서 절대 경로로 변환
        let sourcePathsForScript = config.sourcePaths
            .map { path in
                // 절대 경로로 시작하면 그대로 사용
                if path.hasPrefix("/") {
                    return path
                }
                // 상대 경로면 ${SRCROOT}/../.. 형태로 변환
                return "${SRCROOT}/../../\(path)"
            }
            .joined(separator: " ")

        // 스크립트 경로 처리
        let scriptsPathForScript: String
        if config.scriptsPath.hasPrefix("/") {
            // 절대 경로면 그대로 사용
            scriptsPathForScript = config.scriptsPath
        } else {
            // 상대 경로면 ${SRCROOT}/ + 상대경로
            scriptsPathForScript = "${SRCROOT}/\(config.scriptsPath)"
        }

        // sources 생성 (일반 폴더)
        var sourcesArray = ["\"\(config.appName)/Sources/**\""]
        for case let .folder(path) in config.sourcePathTypes {
            // 절대 경로면 그대로, 상대 경로면 ../../ 붙임
            if path.hasPrefix("/") {
                // 절대 경로는 그대로 사용
                sourcesArray.append("\"\(path)/**\"")
            } else {
                // 상대 경로는 Projects/Sample 기준으로 ../../ 추가
                sourcesArray.append("\"../../\(path)/**\"")
            }
        }

        // dependencies 생성 (Tuist 모듈)
        var dependenciesArray = [
            "// AsyncNetworkDocKit (로컬 SPM 패키지)",
            ".external(name: \"AsyncNetworkDocKit\"),",
            "// AsyncNetwork (로컬 SPM 패키지)",
            ".external(name: \"AsyncNetwork\"),",
        ]
        for case let .tuistModule(path, moduleName) in config.sourcePathTypes {
            let relativePath = path.hasPrefix("/") ? path : "../../\(path)"
            dependenciesArray.append("// \(moduleName) (Tuist 모듈)")
            dependenciesArray.append(".project(target: \"\(moduleName)\", path: \"\(relativePath)\"),")
        }

        return """
        import ProjectDescription
        import ProjectDescriptionHelpers

        let project = Project(
            name: "\(config.appName)",
            targets: [
                .target(
                    name: "\(config.appName)",
                    destinations: .iOS,
                    product: .app,
                    bundleId: "\(config.bundleIdPrefix).\(config.appName)",
                    deploymentTargets: .iOS("17.0"),
                    infoPlist: .extendingDefault(
                        with: [
                            "CFBundleShortVersionString": "1.0.0",
                            "CFBundleVersion": "1",
                            "UILaunchScreen": [:],
                        ]
                    ),
            sources: [\(sourcesArray.joined(separator: ", "))],
            resources: ["\(config.appName)/Resources/**"],
                    scripts: [
                        // 자동 코드 생성 스크립트
                        .pre(
                            script: \"\"\"
                            set -e
                            
                            SCRIPTS_DIR="\(scriptsPathForScript)"
                            OUTPUT_DIR="${SRCROOT}/\(config.appName)/Sources"
                            
                            echo "🔄 Generating code..."
                            
                            # 1. TypeRegistration 생성
                            if [ -f "$SCRIPTS_DIR/GenerateTypeRegistration.swift" ]; then
                                echo "  📝 Generating type registration..."
                                xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateTypeRegistration.swift" \\\\
                                    --project \(sourcePathsForScript) \\\\
                                    --output "$OUTPUT_DIR/TypeRegistration+Generated.swift" \\\\
                                    --module "\(config.appName)" \\\\
                                    --target "\(config.appName)App"
                                
                                if [ $? -eq 0 ]; then
                                    echo "  ✅ Type registration generated"
                                else
                                    echo "  ❌ Failed to generate type registration"
                                    exit 1
                                fi
                            else
                                echo "  ⚠️  TypeRegistration script not found"
                            fi
                            
                            # 2. Endpoints 생성
                            if [ -f "$SCRIPTS_DIR/GenerateEndpoints.swift" ]; then
                                echo "  📝 Generating endpoints..."
                                xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateEndpoints.swift" \\\\
                                    --project \(sourcePathsForScript) \\\\
                                    --output "$OUTPUT_DIR/Endpoints+Generated.swift" \\\\
                                    --module "\(config.appName)" \\\\
                                    --target "\(config.appName)App"
                                
                                if [ $? -eq 0 ]; then
                                    echo "  ✅ Endpoints generated"
                                else
                                    echo "  ❌ Failed to generate endpoints"
                                    exit 1
                                fi
                            else
                                echo "  ⚠️  Endpoints script not found"
                            fi
                            
                            echo "✨ Code generation completed"
                            \"\"\",
                            name: "Generate Code",
                            basedOnDependencyAnalysis: false
                        ),
                    ],
            dependencies: [
                \(dependenciesArray.joined(separator: "\n                "))
            ],
                    settings: .appSettings()
                ),
            ],
            schemes: [
                .appScheme(
                    name: "\(config.appName)",
                    testTargets: []
                ),
            ]
        )

        """
    }

    // MARK: - App 파일 생성

    func generateAppFile() -> String {
        """
        //
        //  \(config.appName)App.swift
        //  \(config.appName)
        //
        //  Created by CreateDocKitExample.swift on \(ISO8601DateFormatter().string(from: Date()))
        //

        import SwiftUI
        import AsyncNetworkDocKit
        import AsyncNetwork

        @main
        @available(iOS 17.0, *)
        struct \(config.appName)App: App {
            let networkService = NetworkService()

            init() {
                // 모든 @DocumentedType 타입을 자동으로 등록
                // GenerateTypeRegistration.swift 스크립트가 빌드 시 자동 생성합니다
                registerAllTypesGenerated()
            }

            var body: some Scene {
                DocKitFactory.createDocApp(
                    endpoints: Self.endpointsGenerated,  // 자동 생성!
                    networkService: networkService,
                    appTitle: "\(config.appName.replacingOccurrences(of: "DocKitExample", with: "")) API Documentation"
                )
            }
        }

        """
    }

    // MARK: - README 생성

    func generateReadme() -> String {
        """
        # \(config.appName)

        AsyncNetworkDocKit을 사용한 API 문서 샘플 앱입니다.

        ## 🎯 자동 생성됨

        이 프로젝트는 `CreateDocKitExample.swift` 스크립트로 자동 생성되었습니다.

        ## 📦 구조

        ```
        \(config.appName)/
        ├── Project.swift                    # Tuist 프로젝트 정의
        ├── \(config.appName)/
        │   └── Sources/
        │       ├── \(config.appName)App.swift          # 메인 앱
        │       ├── TypeRegistration+Generated.swift  # 자동 생성
        │       └── Endpoints+Generated.swift         # 자동 생성
        └── README.md
        ```

        ## 🔄 코드 자동 생성

        빌드 시 다음 파일들이 자동으로 생성됩니다:

        1. **TypeRegistration+Generated.swift**
           - 소스 경로: \(config.sourcePaths.joined(separator: ", "))
           - 모든 `@DocumentedType` 타입을 스캔하여 자동 등록

        2. **Endpoints+Generated.swift**
           - 소스 경로: \(config.sourcePaths.joined(separator: ", "))
           - 모든 `@APIRequest` 타입을 스캔하여 카테고리별로 자동 분류

        ## 🚀 실행 방법

        ### Tuist 프로젝트 생성

        ```bash
        tuist generate
        ```

        ### Xcode에서 실행

        1. `\(config.appName).xcworkspace` 열기
        2. 시뮬레이터 선택
        3. **Cmd + R** 실행

        ## 📝 새 타입/Request 추가

        1. 소스 코드에 `@DocumentedType` 또는 `@APIRequest` 추가
        2. 프로젝트 빌드
        3. 자동으로 문서에 반영됨!

        ## 🛠 수동 코드 생성 (디버깅용)

        ```bash
        # TypeRegistration 생성
        swift \(config.scriptsPath)/GenerateTypeRegistration.swift \\
            --project "\(config.sourcePaths.joined(separator: " "))" \\
            --output "\(config.appName)/Sources/TypeRegistration+Generated.swift" \\
            --module "\(config.appName)" \\
            --target "\(config.appName)App"

        # Endpoints 생성
        swift \(config.scriptsPath)/GenerateEndpoints.swift \\
            --project "\(config.sourcePaths.joined(separator: " "))" \\
            --output "\(config.appName)/Sources/Endpoints+Generated.swift" \\
            --module "\(config.appName)" \\
            --target "\(config.appName)App"
        ```

        """
    }

    // MARK: - .gitignore 생성

    func generateGitignore() -> String {
        """
        # Xcode
        *.xcodeproj
        *.xcworkspace
        .DS_Store

        # Tuist
        Derived/

        # 자동 생성 파일
        **/TypeRegistration+Generated.swift
        **/Endpoints+Generated.swift

        """
    }
}

// MARK: - Directory Creator

struct DirectoryCreator {
    let config: DocKitExampleConfig

    func createDirectoryStructure() throws {
        let fileManager = FileManager.default
        let projectPath = config.outputPath

        // 메인 디렉토리 생성
        try fileManager.createDirectory(
            atPath: projectPath,
            withIntermediateDirectories: true
        )

        // Sources 디렉토리
        try fileManager.createDirectory(
            atPath: "\(projectPath)/\(config.appName)/Sources",
            withIntermediateDirectories: true
        )

        // Resources 디렉토리
        try fileManager.createDirectory(
            atPath: "\(projectPath)/\(config.appName)/Resources",
            withIntermediateDirectories: true
        )

        print("✅ Directory structure created at: \(projectPath)")
    }
}

// MARK: - Path Analyzer

enum PathAnalyzer {
    /// 경로가 Tuist 모듈인지 일반 폴더인지 분석
    static func analyzeSourcePath(_ path: String) -> SourcePathType {
        let normalizedPath = InteractiveInput.normalizePath(path)
        let projectSwiftPath = (normalizedPath as NSString).appendingPathComponent("Project.swift")

        // Project.swift가 있으면 Tuist 모듈
        if FileManager.default.fileExists(atPath: projectSwiftPath) {
            let moduleName = (normalizedPath as NSString).lastPathComponent
            return .tuistModule(path: normalizedPath, moduleName: moduleName)
        }

        // 없으면 일반 폴더
        return .folder(path: normalizedPath)
    }

    /// 여러 경로 분석
    static func analyzeSourcePaths(_ paths: [String]) -> [SourcePathType] {
        return paths.map { analyzeSourcePath($0) }
    }
}

// MARK: - Interactive Input

enum InteractiveInput {
    static func readLine(prompt: String, allowEmpty: Bool = false) -> String? {
        print(prompt, terminator: " ")
        guard let input = Swift.readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }

        if input.isEmpty, !allowEmpty {
            return nil
        }

        // 따옴표 제거 (작은따옴표, 큰따옴표)
        let cleaned = input
            .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    static func readMultipleLines(prompt: String, separator: String = ",") -> [String] {
        print(prompt)
        print("💡 여러 개는 '\(separator)'로 구분하세요 (예: path1\(separator)path2)")
        print("입력:", terminator: " ")

        guard let input = Swift.readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !input.isEmpty
        else {
            return []
        }

        // 따옴표 제거 후 분리
        let cleaned = input.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))

        return cleaned.split(separator: Character(separator))
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
            }
            .filter { !$0.isEmpty }
    }

    static func confirm(prompt: String) -> Bool {
        while true {
            print(prompt, terminator: " ")
            if let input = Swift.readLine()?.lowercased() {
                switch input {
                case "y", "yes", "예":
                    return true
                case "n", "no", "아니오":
                    return false
                default:
                    print("❌ 'y' 또는 'n'을 입력하세요")
                }
            }
        }
    }

    // 경로 정규화
    static func normalizePath(_ path: String) -> String {
        var normalized = path

        // 따옴표 제거
        normalized = normalized.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))

        // ~ 확장
        if normalized.hasPrefix("~") {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            normalized = normalized.replacingOccurrences(of: "~", with: homeDir)
        }

        // 상대 경로를 절대 경로로 변환
        if !normalized.hasPrefix("/") {
            let currentDir = FileManager.default.currentDirectoryPath
            normalized = (currentDir as NSString).appendingPathComponent(normalized)
        }

        // 경로 정규화 (., .. 처리)
        normalized = (normalized as NSString).standardizingPath

        return normalized
    }
}

// MARK: - Main Script

struct CreateDocKitExampleScript {
    func run() {
        printBanner()

        // 커맨드 라인 인자가 있으면 기존 방식 사용
        if CommandLine.arguments.count > 1 {
            runWithArguments()
        } else {
            runInteractive()
        }
    }

    // MARK: - Interactive Mode

    func runInteractive() {
        print("\n🎯 대화형 모드로 DocKitExample 앱을 생성합니다")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

        // 1. 앱 이름 입력
        guard let appName = InteractiveInput.readLine(
            prompt: "📱 앱 이름을 입력하세요 (예: MyAPIDocKitExample):"
        ) else {
            print("❌ 앱 이름은 필수입니다")
            exit(1)
        }
        print("   ✓ 앱 이름: \(appName)\n")

        // 2. @DocumentedType 경로 입력
        print("📁 @DocumentedType을 찾을 경로를 입력하세요")
        print("   모델/타입 정의가 있는 위치 (Models, Domain 등)")
        print("   💡 따옴표 없이 입력하세요!")
        let documentedTypePathsRaw = InteractiveInput.readMultipleLines(prompt: "   ")

        if documentedTypePathsRaw.isEmpty {
            print("❌ 최소 1개 이상의 경로가 필요합니다")
            exit(1)
        }

        print()

        // 3. @APIRequest 경로 입력
        print("📡 @APIRequest를 찾을 경로를 입력하세요")
        print("   API Request 정의가 있는 위치 (Data, Network 등)")
        print("   💡 따옴표 없이 입력하세요!")
        print("   💡 위에서 입력한 경로와 같으면 그냥 Enter를 누르세요")
        let apiRequestPathsRaw = InteractiveInput.readMultipleLines(prompt: "   ")

        // 경로 합치기 및 중복 제거
        var allPathsRaw = documentedTypePathsRaw
        for path in apiRequestPathsRaw {
            if !allPathsRaw.contains(path) {
                allPathsRaw.append(path)
            }
        }

        // 경로 정규화
        let sourcePaths = allPathsRaw.map { InteractiveInput.normalizePath($0) }

        // 경로 타입 분석 ✨
        let sourcePathTypes = PathAnalyzer.analyzeSourcePaths(sourcePaths)

        print("\n   ✓ 모든 소스 경로:")
        for (index, pathType) in sourcePathTypes.enumerated() {
            switch pathType {
            case let .tuistModule(path, moduleName):
                print("     \(index + 1). \(path) [Tuist 모듈: \(moduleName)]")
            case let .folder(path):
                print("     \(index + 1). \(path) [일반 폴더]")
            }
        }
        print()

        // 4. 출력 경로 입력
        print("📂 출력 경로를 입력하세요")
        print("   💡 따옴표 없이 입력하세요!")
        guard let outputPathRaw = InteractiveInput.readLine(
            prompt: "입력 (예: Projects/MyAPIDocKitExample):"
        ) else {
            print("❌ 출력 경로는 필수입니다")
            exit(1)
        }

        // 경로 정규화
        let outputPath = InteractiveInput.normalizePath(outputPathRaw)
        print("   ✓ 출력 경로: \(outputPath)\n")

        // 5. Bundle ID (선택)
        print("🔖 Bundle ID 접두사를 입력하세요 (선택, 기본값: com.asyncnetwork)")
        let bundleIdInput = InteractiveInput.readLine(prompt: "입력:", allowEmpty: true)
        let bundleIdPrefix = bundleIdInput ?? "com.asyncnetwork"
        print("   ✓ Bundle ID: \(bundleIdPrefix).\(appName)\n")

        // 6. 스크립트 경로 (선택)
        print("🛠  스크립트 경로를 입력하세요 (선택, 기본값: ../../Scripts)")
        print("   💡 상대 경로 또는 절대 경로 모두 가능")
        let scriptsInput = InteractiveInput.readLine(prompt: "입력:", allowEmpty: true)
        let scriptsPath = scriptsInput ?? "../../Scripts"
        print("   ✓ 스크립트 경로: \(scriptsPath)\n")

        // 7. 경로 검증
        print("🔍 경로 검증 중...")

        // 소스 경로 검증
        var validSourcePaths: [String] = []
        var validSourcePathTypes: [SourcePathType] = []

        for pathType in sourcePathTypes {
            let path: String
            switch pathType {
            case let .tuistModule(p, moduleName):
                path = p
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                    validSourcePaths.append(path)
                    validSourcePathTypes.append(pathType)
                    print("   ✅ \(path) [Tuist 모듈: \(moduleName)]")
                } else {
                    print("   ⚠️  \(path) - 존재하지 않습니다")
                }
            case let .folder(p):
                path = p
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                    validSourcePaths.append(path)
                    validSourcePathTypes.append(pathType)
                    print("   ✅ \(path) [일반 폴더]")
                } else {
                    print("   ⚠️  \(path) - 존재하지 않습니다")
                }
            }
        }

        if validSourcePaths.isEmpty {
            print("\n❌ 유효한 소스 경로가 없습니다")
            exit(1)
        }
        print()

        // 출력 경로가 이미 존재하는지 확인
        if FileManager.default.fileExists(atPath: outputPath) {
            print("⚠️  출력 경로가 이미 존재합니다: \(outputPath)")
            if !InteractiveInput.confirm(prompt: "   덮어쓰시겠습니까? (y/n):") {
                print("\n❌ 프로젝트 생성이 취소되었습니다")
                exit(0)
            }
            print()
        }

        // 8. 확인
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 최종 설정 확인")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📱 앱 이름:        \(appName)")
        print("🔖 Bundle ID:      \(bundleIdPrefix).\(appName)")
        print("📁 소스 경로:      \(validSourcePaths.joined(separator: "\n                   "))")
        print("📂 출력 경로:      \(outputPath)")
        print("🛠  스크립트 경로:  \(scriptsPath)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

        if !InteractiveInput.confirm(prompt: "🎯 프로젝트를 생성하시겠습니까? (y/n):") {
            print("\n❌ 프로젝트 생성이 취소되었습니다")
            exit(0)
        }

        print()

        // 설정 생성
        let config = DocKitExampleConfig(
            appName: appName,
            bundleIdPrefix: bundleIdPrefix,
            sourcePaths: validSourcePaths,
            sourcePathTypes: validSourcePathTypes, // ✨
            outputPath: outputPath,
            scriptsPath: scriptsPath
        )

        // 프로젝트 생성
        createProject(with: config)
    }

    // MARK: - Argument Mode

    func runWithArguments() {
        // 인자 파싱
        guard let config = parseArguments() else {
            printUsage()
            exit(1)
        }

        // 프로젝트 생성
        createProject(with: config)
    }

    // MARK: - Project Creation

    func createProject(with config: DocKitExampleConfig) {
        do {
            // 1. 디렉토리 생성
            print("📁 디렉토리 구조 생성 중...")
            let dirCreator = DirectoryCreator(config: config)
            try dirCreator.createDirectoryStructure()

            // 2. 파일 생성
            print("📝 파일 생성 중...")
            let generator = FileGenerator(config: config)

            // Project.swift
            let projectSwift = generator.generateProjectSwift()
            try projectSwift.write(
                toFile: "\(config.outputPath)/Project.swift",
                atomically: true,
                encoding: .utf8
            )
            print("  ✅ Project.swift")

            // App 파일
            let appFile = generator.generateAppFile()
            try appFile.write(
                toFile: "\(config.outputPath)/\(config.appName)/Sources/\(config.appName)App.swift",
                atomically: true,
                encoding: .utf8
            )
            print("  ✅ \(config.appName)App.swift")

            // Placeholder 파일 생성 ✨
            print("  📝 Placeholder 파일 생성 중...")
            try createPlaceholderFiles(config: config)

            // README
            let readme = generator.generateReadme()
            try readme.write(
                toFile: "\(config.outputPath)/README.md",
                atomically: true,
                encoding: .utf8
            )
            print("  ✅ README.md")

            // .gitignore
            let gitignore = generator.generateGitignore()
            try gitignore.write(
                toFile: "\(config.outputPath)/.gitignore",
                atomically: true,
                encoding: .utf8
            )
            print("  ✅ .gitignore")

            // 3. 완료 메시지
            printSuccess(config: config)

        } catch {
            print("\n❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    // MARK: - Placeholder 파일 생성

    func createPlaceholderFiles(config: DocKitExampleConfig) throws {
        let sourcesPath = "\(config.outputPath)/\(config.appName)/Sources"

        // TypeRegistration+Generated.swift
        let typeRegPlaceholder = """
        //
        //  TypeRegistration+Generated.swift
        //  \(config.appName)
        //
        //  Auto-generated placeholder
        //  Created by CreateDocKitExample.swift
        //
        //  이 파일은 빌드 시 자동으로 업데이트됩니다.
        //

        import AsyncNetworkCore

        extension \(config.appName)App {
            /// 모든 @DocumentedType 타입을 자동으로 등록합니다
            ///
            /// 이 메서드는 빌드 시 자동 생성됩니다.
            func registerAllTypesGenerated() {
                // 빌드 시 자동으로 채워집니다
            }
        }

        """

        try typeRegPlaceholder.write(
            toFile: "\(sourcesPath)/TypeRegistration+Generated.swift",
            atomically: true,
            encoding: .utf8
        )
        print("    ✅ TypeRegistration+Generated.swift (placeholder)")

        // Endpoints+Generated.swift
        let endpointsPlaceholder = """
        //
        //  Endpoints+Generated.swift
        //  \(config.appName)
        //
        //  Auto-generated placeholder
        //  Created by CreateDocKitExample.swift
        //
        //  이 파일은 빌드 시 자동으로 업데이트됩니다.
        //

        import AsyncNetworkDocKit

        extension \(config.appName)App {
            /// 모든 API Endpoint 정보를 반환합니다
            ///
            /// 이 프로퍼티는 빌드 시 자동 생성됩니다.
            static var endpointsGenerated: [String: [EndpointMetadata]] {
                [:] // 빌드 시 자동으로 채워집니다
            }
        }

        """

        try endpointsPlaceholder.write(
            toFile: "\(sourcesPath)/Endpoints+Generated.swift",
            atomically: true,
            encoding: .utf8
        )
        print("    ✅ Endpoints+Generated.swift (placeholder)")
    }

    // MARK: - Print Methods

    func printBanner() {
        print("""

        ╔═══════════════════════════════════════════════════════════╗
        ║                                                           ║
        ║   🚀 CreateDocKitExample                                 ║
        ║      DocKitExample 앱 자동 생성 스크립트                    ║
        ║                                                           ║
        ╚═══════════════════════════════════════════════════════════╝

        """)
    }

    func printSuccess(config: DocKitExampleConfig) {
        print("""

        ╔═══════════════════════════════════════════════════════════╗
        ║                                                           ║
        ║   ✨ 프로젝트 생성 완료!                                   ║
        ║                                                           ║
        ╚═══════════════════════════════════════════════════════════╝

        📦 프로젝트: \(config.appName)
        📍 위치: \(config.outputPath)

        🎯 다음 단계:

          1️⃣  프로젝트로 이동
             $ cd \(config.outputPath)

          2️⃣  Tuist 프로젝트 생성
             $ tuist generate

          3️⃣  Xcode에서 열기
             $ open \(config.appName).xcworkspace

          4️⃣  빌드 및 실행 (⌘ + R)

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        💡 팁: 빌드 시 자동으로 다음 파일들이 생성됩니다:
           • TypeRegistration+Generated.swift
           • Endpoints+Generated.swift
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }

    // MARK: - Argument Parsing

    func parseArguments() -> DocKitExampleConfig? {
        let args = CommandLine.arguments

        var appName: String?
        var bundleIdPrefix = "com.asyncnetwork"
        var sourcePaths: [String] = []
        var outputPath: String?
        var scriptsPath = "../../Scripts"

        var i = 1
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "--name", "-n":
                guard i + 1 < args.count else { return nil }
                appName = args[i + 1]
                i += 2

            case "--bundle-id", "-b":
                guard i + 1 < args.count else { return nil }
                bundleIdPrefix = args[i + 1]
                i += 2

            case "--sources", "-s":
                guard i + 1 < args.count else { return nil }
                sourcePaths.append(args[i + 1])
                i += 2

            case "--output", "-o":
                guard i + 1 < args.count else { return nil }
                outputPath = args[i + 1]
                i += 2

            case "--scripts", "-sp":
                guard i + 1 < args.count else { return nil }
                scriptsPath = args[i + 1]
                i += 2

            case "--help", "-h":
                return nil

            default:
                print("❌ Unknown argument: \(arg)")
                return nil
            }
        }

        // 필수 인자 검증
        guard let name = appName,
              !sourcePaths.isEmpty,
              let output = outputPath
        else {
            print("❌ Missing required arguments")
            return nil
        }

        // 경로 타입 분석 ✨
        let sourcePathTypes = PathAnalyzer.analyzeSourcePaths(sourcePaths)

        return DocKitExampleConfig(
            appName: name,
            bundleIdPrefix: bundleIdPrefix,
            sourcePaths: sourcePaths,
            sourcePathTypes: sourcePathTypes, // ✨
            outputPath: output,
            scriptsPath: scriptsPath
        )
    }

    // MARK: - Usage

    func printUsage() {
        print("""

        📖 사용법:

          swift CreateDocKitExample.swift \\
              --name <앱이름> \\
              --sources <소스경로1> [--sources <소스경로2> ...] \\
              --output <출력경로> \\
              [--bundle-id <번들ID>] \\
              [--scripts <스크립트경로>]

        필수 인자:
          --name, -n          앱 이름 (예: MyAPIDocKitExample)
          --sources, -s       APIRequest/DocumentedType를 찾을 소스 경로 (여러 개 가능)
          --output, -o        샘플앱을 생성할 위치

        선택 인자:
          --bundle-id, -b     Bundle ID 접두사 (기본값: com.asyncnetwork)
          --scripts, -sp      GenerateTypeRegistration.swift 스크립트 경로 (기본값: ../../Scripts)
          --help, -h          도움말 표시

        예시:

          # 단일 소스 경로
          swift CreateDocKitExample.swift \\
              --name MyAPIDocKitExample \\
              --sources ../MyAPI/Sources \\
              --output ./Projects/MyAPIDocKitExample

          # 여러 소스 경로
          swift CreateDocKitExample.swift \\
              --name MyAPIDocKitExample \\
              --sources ../MyAPI/Sources \\
              --sources ../MyModels/Sources \\
              --output ./Projects/MyAPIDocKitExample \\
              --bundle-id com.mycompany

          # 커스텀 스크립트 경로
          swift CreateDocKitExample.swift \\
              --name MyAPIDocKitExample \\
              --sources ../MyAPI/Sources \\
              --output ./Projects/MyAPIDocKitExample \\
              --scripts ./Scripts

        """)
    }
}

// MARK: - Entry Point

let script = CreateDocKitExampleScript()
script.run()
