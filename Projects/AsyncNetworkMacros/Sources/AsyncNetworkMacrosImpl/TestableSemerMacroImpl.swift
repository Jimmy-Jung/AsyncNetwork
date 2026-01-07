//
//  TestableSemerMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/06.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @TestableSchemer 매크로 구현
///
/// @APIRequest와 연동하여 API 테스트 시나리오를 자동 생성합니다.
public struct TestableSemerMacroImpl: MemberMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. struct 검증
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw TestableSemerMacroError.notAStruct
        }

        let typeName = structDecl.name.text

        // 2. @APIRequest가 있는지 확인
        guard hasAPIRequestMacro(structDecl) else {
            throw TestableSemerMacroError.missingAPIRequest
        }

        // 3. 매크로 인자 파싱
        let args = try parseTestableSemerArguments(from: node)

        // 4. Response 타입 추출 (from @APIRequest)
        let responseType = try extractResponseType(from: structDecl)

        // 5. 멤버 생성
        var members: [DeclSyntax] = []

        // MockScenario enum
        members.append(generateMockScenarioEnum(scenarios: args.scenarios))

        // mockResponse() 메서드
        members.append(generateMockResponseMethod(
            typeName: typeName,
            responseType: responseType,
            scenarios: args.scenarios,
            errorExamples: args.errorExamples
        ))

        return members
    }

    // MARK: - Helper Methods

    /// MockScenario enum 생성
    private static func generateMockScenarioEnum(scenarios: [String]) -> DeclSyntax {
        // 기본 시나리오 + 사용자 정의 시나리오
        let allScenarios = ["success", "notFound", "serverError", "networkError", "timeout"] + scenarios
        let uniqueScenarios = Array(Set(allScenarios)).sorted()

        let cases = uniqueScenarios.map { "case \($0)" }.joined(separator: "\n    ")

        return """
        /// Mock 테스트 시나리오
        enum MockScenario {
            \(raw: cases)
        }
        """
    }

    /// mockResponse() 메서드 생성
    private static func generateMockResponseMethod(
        typeName _: String,
        responseType: String,
        scenarios _: [String],
        errorExamples: [String: String]
    ) -> DeclSyntax {
        var cases = """
        switch scenario {
            case .success:
                let response = \(responseType).fixture()
                let data = try? JSONEncoder().encode(response)
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
                return (data, httpResponse, nil)
            
            case .notFound:
        """

        // 404 에러
        if let notFoundJSON = errorExamples["404"] {
            let escaped = escapeJSON(notFoundJSON)
            cases += """

                    let errorData = Data(\"\(escaped)\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 404,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
            """
        } else {
            cases += """

                    let errorData = Data(\"\"\"
                    {
                        "error": "Not found",
                        "code": "NOT_FOUND"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 404,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
            """
        }

        // 500 에러
        cases += """

            case .serverError:
        """

        if let serverErrorJSON = errorExamples["500"] {
            let escaped = escapeJSON(serverErrorJSON)
            cases += """

                    let errorData = Data(\"\(escaped)\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 500,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
            """
        } else {
            cases += """

                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 500,
                        httpVersion: nil,
                        headerFields: nil
                    )
                    return (nil, httpResponse, nil)
            """
        }

        // 네트워크 에러
        cases += """

            case .networkError:
                return (nil, nil, URLError(.notConnectedToInternet))
            
            case .timeout:
                return (nil, nil, URLError(.timedOut))
            }
        """

        return """
        /// Mock 응답 제공자
        static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
            let url = URL(string: "https://api.example.com")!
            
            \(raw: cases)
        }
        """
    }

    /// Tests 스위트 생성
    private static func generateTestsSuite(
        typeName: String,
        responseType _: String,
        scenarios _: [String],
        includeRetryTests: Bool,
        includePerformanceTests: Bool
    ) -> DeclSyntax {
        var tests = """
        @Suite("\(typeName) API Tests")
            struct Tests {
                let service: NetworkService
                
                init() {
                    let config = URLSessionConfiguration.ephemeral
                    config.protocolClasses = [MockURLProtocol.self]
                    self.service = NetworkService(configuration: NetworkConfiguration(
                        urlSessionConfiguration: config,
                        enableLogging: false
                    ))
                }
                
                // MARK: Success Tests
                
                @Test("성공 시나리오")
                func testSuccess() async throws {
                    // Given
                    MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .success)
                    let request = \(typeName)()
                    
                    // When
                    let response = try await service.request(request)
                    
                    // Then
                    #expect(response != nil)
                }
                
                // MARK: Error Tests
                
                @Test("404 에러 - Not Found")
                func testNotFound() async {
                    // Given
                    MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .notFound)
                    let request = \(typeName)()
                    
                    // When/Then
                    await #expect(throws: Error.self) {
                        try await service.request(request)
                    }
                }
                
                @Test("500 에러 - Server Error")
                func testServerError() async {
                    // Given
                    MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .serverError)
                    let request = \(typeName)()
                    
                    // When/Then
                    await #expect(throws: Error.self) {
                        try await service.request(request)
                    }
                }
                
                @Test("네트워크 에러")
                func testNetworkError() async {
                    // Given
                    MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .networkError)
                    let request = \(typeName)()
                    
                    // When/Then
                    await #expect(throws: URLError.self) {
                        try await service.request(request)
                    }
                }
        """

        // 재시도 테스트
        if includeRetryTests {
            tests += """

                    
                    // MARK: Retry Tests
                    
                    @Test("재시도 로직 - 최종 성공", arguments: [1, 2, 3])
                    func testRetrySuccess(maxRetries: Int) async throws {
                        // Given
                        var attemptCount = 0
                        MockURLProtocol.mockHandler = { _ in
                            attemptCount += 1
                            if attemptCount <= maxRetries {
                                return \(typeName).mockResponse(for: .networkError)
                            } else {
                                return \(typeName).mockResponse(for: .success)
                            }
                        }
                        
                        let request = \(typeName)()
                        let policy = RetryPolicy(maxRetries: maxRetries, delay: 0.01)
                        
                        // When
                        let response = try await service.request(request, retryPolicy: policy)
                        
                        // Then
                        #expect(attemptCount == maxRetries + 1)
                        #expect(response != nil)
                    }
                    
                    @Test("재시도 최대 횟수 초과")
                    func testMaxRetriesExceeded() async {
                        // Given
                        MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .timeout)
                        let request = \(typeName)()
                        let policy = RetryPolicy(maxRetries: 3, delay: 0.01)
                        
                        // When/Then
                        await #expect(throws: Error.self) {
                            try await service.request(request, retryPolicy: policy)
                        }
                    }
            """
        }

        // 성능 테스트
        if includePerformanceTests {
            tests += """

                    
                    // MARK: Performance Tests
                    
                    @Test("성능 테스트 - 단일 요청")
                    func testPerformanceSingle() async throws {
                        // Given
                        MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .success)
                        let request = \(typeName)()
                        
                        // When
                        let start = Date()
                        _ = try await service.request(request)
                        let duration = Date().timeIntervalSince(start)
                        
                        // Then
                        #expect(duration < 1.0) // 1초 이내
                    }
                    
                    @Test("성능 테스트 - 동시 요청")
                    func testPerformanceConcurrent() async throws {
                        // Given
                        MockURLProtocol.mockResponse = \(typeName).mockResponse(for: .success)
                        
                        // When
                        let start = Date()
                        try await withThrowingTaskGroup(of: Void.self) { group in
                            for _ in 0..<10 {
                                group.addTask {
                                    let request = \(typeName)()
                                    _ = try await self.service.request(request)
                                }
                            }
                            try await group.waitForAll()
                        }
                        let duration = Date().timeIntervalSince(start)
                        
                        // Then
                        #expect(duration < 2.0) // 2초 이내
                    }
            """
        }

        tests += """
            
            }
        """

        return DeclSyntax(stringLiteral: tests)
    }

    /// JSON escape 처리
    private static func escapeJSON(_ json: String) -> String {
        return json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    /// @APIRequest 매크로 존재 여부 확인
    private static func hasAPIRequestMacro(_ structDecl: StructDeclSyntax) -> Bool {
        for attribute in structDecl.attributes {
            if let attr = attribute.as(AttributeSyntax.self),
               let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
               identifier.name.text == "APIRequest"
            {
                return true
            }
        }
        return false
    }

    /// @APIRequest에서 Response 타입 추출
    private static func extractResponseType(from structDecl: StructDeclSyntax) throws -> String {
        for attribute in structDecl.attributes {
            if let attr = attribute.as(AttributeSyntax.self),
               let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
               identifier.name.text == "APIRequest",
               let arguments = attr.arguments?.as(LabeledExprListSyntax.self)
            {
                for argument in arguments {
                    if argument.label?.text == "response",
                       let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
                       let base = memberAccess.base
                    {
                        return base.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }

        throw TestableSemerMacroError.missingResponseType
    }
}

// MARK: - Supporting Types

struct TestableSemerArguments {
    let scenarios: [String]
    let includeRetryTests: Bool
    let errorExamples: [String: String]
    let includePerformanceTests: Bool
}

// MARK: - Argument Parsing

func parseTestableSemerArguments(from node: AttributeSyntax) throws -> TestableSemerArguments {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        // 기본값 사용
        return TestableSemerArguments(
            scenarios: [],
            includeRetryTests: true,
            errorExamples: [:],
            includePerformanceTests: false
        )
    }

    var scenarios: [String] = []
    var includeRetryTests = true
    var errorExamples: [String: String] = [:]
    var includePerformanceTests = false

    for argument in arguments {
        let label = argument.label?.text ?? ""
        let expr = argument.expression

        switch label {
        case "scenarios":
            scenarios = extractScenarios(from: expr)
        case "includeRetryTests":
            if let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) {
                includeRetryTests = boolLiteral.literal.text == "true"
            }
        case "errorExamples":
            errorExamples = extractErrorExamples(from: expr)
        case "includePerformanceTests":
            if let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) {
                includePerformanceTests = boolLiteral.literal.text == "true"
            }
        default:
            break
        }
    }

    return TestableSemerArguments(
        scenarios: scenarios,
        includeRetryTests: includeRetryTests,
        errorExamples: errorExamples,
        includePerformanceTests: includePerformanceTests
    )
}

func extractScenarios(from expr: ExprSyntax) -> [String] {
    guard let arrayExpr = expr.as(ArrayExprSyntax.self) else {
        return []
    }

    var scenarios: [String] = []
    for element in arrayExpr.elements {
        if let memberAccess = element.expression.as(MemberAccessExprSyntax.self) {
            scenarios.append(memberAccess.declName.baseName.text)
        }
    }

    return scenarios
}

// extractErrorExamples는 ArgumentParser.swift에 정의되어 있습니다.

// MARK: - Errors

enum TestableSemerMacroError: Error, CustomStringConvertible {
    case notAStruct
    case missingAPIRequest
    case missingResponseType

    var description: String {
        switch self {
        case .notAStruct:
            return "@TestableSchemer can only be applied to struct declarations"
        case .missingAPIRequest:
            return "@TestableSchemer requires @APIRequest to be applied to the same type"
        case .missingResponseType:
            return "Could not extract Response type from @APIRequest"
        }
    }
}
