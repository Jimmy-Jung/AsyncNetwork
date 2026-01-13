//
//  TestGenerator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// 테스트 코드 생성기
///
/// 이 클래스는 `@APITestable` 매크로에서 테스트 관련 코드를 생성합니다:
/// - `enum MockScenario`: 테스트 시나리오 정의
/// - `func mockResponse(for:)`: 시나리오별 Mock 응답 생성
///
/// ## 생성 예시
/// ```swift
/// public enum MockScenario: String, CaseIterable {
///     case success
///     case notFound
///     case serverError
/// }
///
/// public func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
///     // ...
/// }
/// ```
public struct TestGenerator: CodeGenerator {
    private let args: MacroArguments
    private let responseType: String

    public init(
        args: MacroArguments,
        responseType: String
    ) {
        self.args = args
        self.responseType = responseType
    }

    // MARK: - CodeGenerator

    public func generate() -> [DeclSyntax] {
        var declarations: [DeclSyntax] = []

        declarations.append(generateMockScenarioEnum())
        declarations.append(generateMockResponseMethod())

        return declarations
    }

    // MARK: - Private Methods

    /// MockScenario enum 생성
    private func generateMockScenarioEnum() -> DeclSyntax {
        var cases = ["success"]

        // errorExamples에서 케이스 추출
        for (statusCode, _) in args.errorExamples.sorted(by: { $0.key < $1.key }) {
            let caseName = getCaseNameForStatusCode(statusCode)
            if !cases.contains(caseName) {
                cases.append(caseName)
            }
        }

        // testScenarios에서 케이스 추가
        for scenario in args.testScenarios {
            if !cases.contains(scenario) {
                cases.append(scenario)
            }
        }

        let casesCode = cases.map { "case \($0)" }.joined(separator: "\n    ")

        return """
        public enum MockScenario: String, CaseIterable {
            \(raw: casesCode)
        }
        """
    }

    /// mockResponse 메서드 생성
    private func generateMockResponseMethod() -> DeclSyntax {
        var switchCases: [String] = []

        // success 케이스
        switchCases.append("""
        case .success:
            let json = "{\\"id\\": 1, \\"title\\": \\"Mock Title\\"}"
            let data = json.data(using: .utf8)
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            return (data, response, nil)
        """)

        // errorExamples 케이스
        for (statusCode, jsonExample) in args.errorExamples.sorted(by: { $0.key < $1.key }) {
            let caseName = getCaseNameForStatusCode(statusCode)
            let escapedJSON = escapeJSON(jsonExample)

            switchCases.append("""
            case .\(caseName):
                let json = "\(escapedJSON)"
                let data = json.data(using: .utf8)
                let response = HTTPURLResponse(
                    url: URL(string: "https://example.com")!,
                    statusCode: \(statusCode),
                    httpVersion: nil,
                    headerFields: nil
                )
                return (data, response, nil)
            """)
        }

        // 기본 케이스
        switchCases.append("""
        default:
            return (nil, nil, URLError(.unknown))
        """)

        let switchBody = switchCases.joined(separator: "\n        ")

        return """
        public func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
            switch scenario {
            \(raw: switchBody)
            }
        }
        """
    }

    /// 상태 코드에서 케이스 이름 생성
    private func getCaseNameForStatusCode(_ statusCode: String) -> String {
        let code = Int(statusCode) ?? 0

        switch code {
        case 400: return "badRequest"
        case 401: return "unauthorized"
        case 403: return "forbidden"
        case 404: return "notFound"
        case 500: return "serverError"
        case 503: return "serviceUnavailable"
        default: return "error\(statusCode)"
        }
    }

    /// JSON 문자열 이스케이프
    private func escapeJSON(_ json: String) -> String {
        return json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
