//
//  AsyncNetworkDocKitExampleApp.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkDocKit
import Foundation
import SwiftUI

@main
@available(iOS 17.0, *)
struct AsyncNetworkDocKitExampleApp: App {
    let networkService = NetworkService()

    init() {
        // 명령줄에서 export-openapi 실행 시
        if CommandLine.arguments.contains("export-openapi") {
            Self.exportOpenAPI()
            exit(0)
        }

        // 모든 @DocumentedType 타입을 자동으로 등록
        // GenerateTypeRegistration.swift 스크립트가 빌드 시 자동 생성합니다
        registerAllTypesGenerated()
    }

    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: Self.endpointsGenerated,
            networkService: networkService,
            appTitle: "AsyncNetwork API Documentation"
        )
    }

    // MARK: - OpenAPI Export

    /// 명령줄에서 OpenAPI 스펙을 내보냅니다
    ///
    /// 사용법:
    /// ```bash
    /// swift run AsyncNetworkDocKitExample export-openapi \
    ///   --output ./openapi.json \
    ///   --format json \
    ///   --title "My API" \
    ///   --version "1.0.0"
    /// ```
    static func exportOpenAPI() {
        let args = CommandLine.arguments

        // 기본값
        var format = "json"
        var outputPath = "./openapi.json"
        var title = "AsyncNetwork API Documentation"
        var version = "1.0.0"
        var description: String?

        // 인자 파싱
        var i = 1
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "--format", "-f":
                if i + 1 < args.count {
                    i += 1
                    format = args[i].lowercased()
                }
            case "--output", "-o":
                if i + 1 < args.count {
                    i += 1
                    outputPath = args[i]
                }
            case "--title", "-t":
                if i + 1 < args.count {
                    i += 1
                    title = args[i]
                }
            case "--version", "-v":
                if i + 1 < args.count {
                    i += 1
                    version = args[i]
                }
            case "--description", "-d":
                if i + 1 < args.count {
                    i += 1
                    description = args[i]
                }
            default:
                break
            }

            i += 1
        }

        print("📊 Exporting OpenAPI specification...")
        print("  Format: \(format.uppercased())")
        print("  Output: \(outputPath)")
        print("  Title: \(title)")
        print("  Version: \(version)")

        do {
            let endpoints = Self.endpointsGenerated
            let endpointCount = endpoints.values.flatMap { $0 }.count
            print("  Endpoints: \(endpointCount)")

            if format == "json" {
                let jsonData = try DocKitFactory.exportToOpenAPIJSON(
                    endpoints: endpoints,
                    title: title,
                    version: version,
                    description: description,
                    prettyPrinted: true
                )
                try jsonData.write(to: URL(fileURLWithPath: outputPath))
            } else {
                let yamlString = DocKitFactory.exportToOpenAPIYAML(
                    endpoints: endpoints,
                    title: title,
                    version: version,
                    description: description
                )
                try yamlString.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            }

            print("✅ OpenAPI specification exported successfully to: \(outputPath)")
        } catch {
            print("❌ Error exporting OpenAPI: \(error.localizedDescription)")
            exit(1)
        }
    }
}
