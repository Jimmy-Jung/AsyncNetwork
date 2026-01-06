#!/usr/bin/env swift

//
//  GenerateEndpoints.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//
//  이 스크립트는 프로젝트의 모든 @APIRequest 타입을 스캔하여
//  자동으로 endpoints 딕셔너리를 생성합니다.
//

import Foundation

// MARK: - RequestInfo

/// API Request 정보를 담는 구조체
struct RequestInfo {
    let name: String // 예: GetAllPostsRequest
    let tags: [String] // 예: ["Posts", "Read"]
    let category: String // 예: "Posts" (첫 번째 태그)

    var metadataProperty: String {
        "\(name).metadata"
    }
}

// MARK: - RequestScanner

/// @APIRequest가 적용된 타입을 스캔하는 클래스
struct RequestScanner {
    let projectPath: String
    let verbose: Bool

    /// 모든 @APIRequest 타입을 스캔합니다
    func scanAPIRequests() throws -> [RequestInfo] {
        var requests: [RequestInfo] = []

        if verbose {
            print("📂 Scanning project: \(projectPath)")
        }

        // 모든 .swift 파일 찾기
        let swiftFiles = try findSwiftFiles(in: projectPath)

        if verbose {
            print("📄 Found \(swiftFiles.count) Swift files")
        }

        for file in swiftFiles {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let fileRequests = extractAPIRequests(from: content, file: file)
            requests.append(contentsOf: fileRequests)
        }

        return requests.sorted { $0.name < $1.name }
    }

    /// 지정된 디렉토리에서 모든 .swift 파일을 찾습니다
    private func findSwiftFiles(in directory: String) throws -> [String] {
        let fileManager = FileManager.default
        var swiftFiles: [String] = []

        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            throw NSError(
                domain: "RequestScanner",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot enumerate directory: \(directory)"]
            )
        }

        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift"), !file.contains("/Generated/"), !file.hasSuffix("+Generated.swift") {
                swiftFiles.append("\(directory)/\(file)")
            }
        }

        return swiftFiles
    }

    /// 파일 내용에서 @APIRequest가 적용된 타입을 추출합니다
    private func extractAPIRequests(from content: String, file: String) -> [RequestInfo] {
        var requests: [RequestInfo] = []
        let lines = content.components(separatedBy: .newlines)

        var i = 0
        while i < lines.count {
            let line = lines[i]

            // @APIRequest( 찾기
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("@APIRequest(") {
                // @APIRequest 블록 전체 추출
                var apiRequestBlock = ""
                var depth = 0
                var foundOpenParen = false

                for j in i ..< lines.count {
                    let currentLine = lines[j]
                    apiRequestBlock += currentLine + "\n"

                    for char in currentLine {
                        if char == "(" {
                            foundOpenParen = true
                            depth += 1
                        } else if char == ")" {
                            depth -= 1
                            if foundOpenParen, depth == 0 {
                                break
                            }
                        }
                    }

                    if foundOpenParen, depth == 0 {
                        i = j
                        break
                    }
                }

                // tags 추출
                let tags = extractTags(from: apiRequestBlock)

                // 다음 줄에서 struct 이름 추출
                if i + 1 < lines.count {
                    let nextLine = lines[i + 1]
                    if let structName = extractStructName(from: nextLine) {
                        let category = tags.first ?? "Uncategorized"
                        let request = RequestInfo(
                            name: structName,
                            tags: tags,
                            category: category
                        )
                        requests.append(request)

                        if verbose {
                            let fileName = URL(fileURLWithPath: file).lastPathComponent
                            print("  ✓ \(structName) → \(category) (in \(fileName))")
                        }
                    }
                }
            }

            i += 1
        }

        return requests
    }

    /// @APIRequest 블록에서 tags를 추출합니다
    private func extractTags(from block: String) -> [String] {
        // tags: ["Posts", "Read"] 형태 추출
        let pattern = #"tags:\s*\[(.*?)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let tagsRange = Range(match.range(at: 1), in: block)
        else {
            return []
        }

        let tagsString = String(block[tagsRange])

        // "Posts", "Read" 형태에서 태그 추출
        let tagPattern = #"\"([^\"]+)\""#
        guard let tagRegex = try? NSRegularExpression(pattern: tagPattern) else {
            return []
        }

        let tagMatches = tagRegex.matches(
            in: tagsString,
            range: NSRange(tagsString.startIndex..., in: tagsString)
        )

        var tags: [String] = []
        for match in tagMatches {
            if let range = Range(match.range(at: 1), in: tagsString) {
                tags.append(String(tagsString[range]))
            }
        }

        return tags
    }

    /// 코드 라인에서 struct 이름을 추출합니다
    private func extractStructName(from line: String) -> String? {
        let pattern = #"struct\s+(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: line,
                  range: NSRange(line.startIndex..., in: line)
              ),
              let nameRange = Range(match.range(at: 1), in: line)
        else {
            return nil
        }

        return String(line[nameRange])
    }
}

// MARK: - CodeGenerator

/// Endpoints 코드를 생성하는 클래스
struct CodeGenerator {
    let moduleName: String
    let targetName: String

    /// 주어진 Request 목록으로부터 endpoints 코드를 생성합니다
    func generateEndpointsCode(requests: [RequestInfo]) -> String {
        // 카테고리별로 그룹화
        var categorizedRequests: [String: [RequestInfo]] = [:]
        for request in requests {
            categorizedRequests[request.category, default: []].append(request)
        }

        // 카테고리 정렬
        let sortedCategories = categorizedRequests.keys.sorted()

        // endpoints 딕셔너리 생성
        var endpointsLines: [String] = []
        for category in sortedCategories {
            let categoryRequests = categorizedRequests[category]!.sorted { $0.name < $1.name }

            endpointsLines.append("            \"\(category)\": [")
            for request in categoryRequests {
                endpointsLines.append("                \(request.metadataProperty),")
            }
            endpointsLines.append("            ],")
        }

        return """
        //
        //  Endpoints+Generated.swift
        //  \(moduleName)
        //
        //  Auto-generated by GenerateEndpoints.swift
        //  Created on \(ISO8601DateFormatter().string(from: Date()))
        //
        //  DO NOT EDIT MANUALLY
        //  This file is automatically regenerated during build.
        //

        import AsyncNetworkDocKit

        extension \(targetName) {
            /// 모든 API Endpoint 정보를 반환합니다
            ///
            /// 이 프로퍼티는 빌드 시 자동 생성되었습니다.
            /// Request를 추가/삭제하면 다음 빌드에서 자동으로 업데이트됩니다.
            ///
            /// - Note: 생성된 카테고리 수: \(sortedCategories.count)개, 총 Endpoint 수: \(requests.count)개
            static var endpointsGenerated: [String: [EndpointMetadata]] {
                [
        \(endpointsLines.joined(separator: "\n"))
                ]
            }
        }

        """
    }
}

// MARK: - Main Execution

do {
    // 인자 파싱
    var projectPath: String?
    var outputPath: String?
    var moduleName = "AsyncNetworkDocKitExample"
    var targetName = "AsyncNetworkDocKitExampleApp"
    var verbose = false

    let args = CommandLine.arguments
    var i = 1
    while i < args.count {
        let arg = args[i]
        switch arg {
        case "--project", "-p":
            i += 1
            if i < args.count {
                projectPath = args[i]
            }
        case "--output", "-o":
            i += 1
            if i < args.count {
                outputPath = args[i]
            }
        case "--module", "-m":
            i += 1
            if i < args.count {
                moduleName = args[i]
            }
        case "--target", "-t":
            i += 1
            if i < args.count {
                targetName = args[i]
            }
        case "--verbose", "-v":
            verbose = true
        case "--help", "-h":
            print("""
            Usage: GenerateEndpoints.swift [options]

            Options:
              -p, --project <path>    프로젝트 소스 디렉토리 경로 (필수)
              -o, --output <path>     출력 파일 경로 (필수)
              -m, --module <name>     모듈 이름 (기본: AsyncNetworkDocKitExample)
              -t, --target <name>     타겟 이름 (기본: AsyncNetworkDocKitExampleApp)
              -v, --verbose           상세 출력
              -h, --help              도움말 표시

            Example:
              ./GenerateEndpoints.swift \\
                --project ./AsyncNetworkDocKitExample/Sources \\
                --output ./AsyncNetworkDocKitExample/Sources/Endpoints+Generated.swift
            """)
            exit(0)
        default:
            break
        }
        i += 1
    }

    guard let projectPath = projectPath, let outputPath = outputPath else {
        print("❌ Error: --project and --output are required")
        print("Run with --help for usage information")
        exit(1)
    }

    // 디렉토리 존재 확인
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: projectPath) else {
        print("❌ Error: Project path does not exist: \(projectPath)")
        exit(1)
    }

    if verbose {
        print("🔍 Endpoints Generator")
        print("   Project: \(projectPath)")
        print("   Output:  \(outputPath)")
        print("   Module:  \(moduleName)")
        print("   Target:  \(targetName)")
        print()
    }

    // Request 스캔
    let scanner = RequestScanner(projectPath: projectPath, verbose: verbose)
    let requests = try scanner.scanAPIRequests()

    if verbose {
        print()
    }
    print("✅ Found \(requests.count) @APIRequest types")

    // 카테고리별 통계
    var categoryCounts: [String: Int] = [:]
    for request in requests {
        categoryCounts[request.category, default: 0] += 1
    }

    if verbose, !requests.isEmpty {
        print("\nCategories:")
        for (category, count) in categoryCounts.sorted(by: { $0.key < $1.key }) {
            print("  - \(category): \(count) endpoints")
        }
    }

    // 코드 생성
    let generator = CodeGenerator(moduleName: moduleName, targetName: targetName)
    let code = generator.generateEndpointsCode(requests: requests)

    // 출력 디렉토리 생성
    let outputDir = URL(fileURLWithPath: outputPath).deletingLastPathComponent().path
    if !fileManager.fileExists(atPath: outputDir) {
        try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    }

    // 파일 쓰기
    try code.write(toFile: outputPath, atomically: true, encoding: .utf8)

    print("📝 Generated: \(outputPath)")

    if verbose {
        print("\n✨ Done!")
    }

} catch {
    print("❌ Error: \(error.localizedDescription)")
    exit(1)
}
