//
//  APITestableMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/12.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - APITestableMacroError

/// APITestable 매크로 에러 타입
public enum APITestableMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    case onlyApplicableToStruct
    case missingAPIRequest

    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@APITestable can only be applied to a struct"
        case .missingAPIRequest:
            return """
            @APITestable requires @APIRequest to be declared first.

            Usage:
            @APIRequest(...)
            @APITestable(...)
            struct YourRequest { }
            """
        }
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "APITestableMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - APITestableMacroImpl

/// @APITestable 매크로 구현
///
/// @APIRequest와 함께 사용하여 테스트 Mock 응답을 생성합니다.
public struct APITestableMacroImpl: MemberMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. 구조체 검증
        let structDecl = try validateStructDeclaration(declaration, node: node, context: context)

        // 2. @APIRequest 매크로 존재 확인
        guard let apiRequestAttr = findAPIRequestAttribute(from: declaration) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APITestableMacroError.missingAPIRequest
            )
            context.diagnose(diagnostic)
            throw APITestableMacroError.missingAPIRequest
        }

        // 3. @APIRequest의 인자 파싱
        let apiRequestArgs = try parseAPIRequestArguments(from: apiRequestAttr, context: context)

        // 4. @APITestable의 인자 파싱
        let testableArgs = try parseAPITestableArguments(from: node, context: context)

        // 5. 기존 멤버 확인
        let existingMembers = collectExistingMembers(from: structDecl)

        // 6. 멤버 생성
        var members: [DeclSyntax] = []

        // MockScenario enum
        if !existingMembers.contains("MockScenario") {
            members.append(generateMockScenarioEnum(
                scenarios: testableArgs.scenarios,
                errorExamples: testableArgs.errorExamples
            ))
        }

        // mockResponse() 메서드
        if !existingMembers.contains("mockResponse") {
            members.append(generateMockResponseMethod(
                typeName: structDecl.name.text,
                responseType: apiRequestArgs.responseType,
                scenarios: testableArgs.scenarios,
                errorExamples: testableArgs.errorExamples
            ))
        }

        return members
    }

    // MARK: - Helper Methods

    /// 구조체 선언을 검증합니다.
    private static func validateStructDeclaration(
        _ declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> StructDeclSyntax {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APITestableMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            throw APITestableMacroError.onlyApplicableToStruct
        }
        return structDecl
    }

    /// declaration에서 @APIRequest 어트리뷰트를 찾습니다.
    private static func findAPIRequestAttribute(
        from declaration: some DeclGroupSyntax
    ) -> AttributeSyntax? {
        for attribute in declaration.attributes {
            if let customAttribute = attribute.as(AttributeSyntax.self),
               customAttribute.attributeName.trimmedDescription == "APIRequest"
            {
                return customAttribute
            }
        }
        return nil
    }

    /// @APIRequest의 인자를 파싱합니다.
    private static func parseAPIRequestArguments(
        from attribute: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> MacroArguments {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            let diagnostic = Diagnostic(
                node: attribute,
                message: APIRequestMacroError.missingArguments
            )
            context.diagnose(diagnostic)
            throw APIRequestMacroError.missingArguments
        }

        // 직접 파싱
        let expressionParser = ExpressionParser()
        let pathParser = PathParser()

        var responseType: String?
        var baseURL: String?
        var isBaseURLLiteral = false
        var path: String?
        var method: String?

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "response":
                responseType = try? expressionParser.extractTypeName(from: expr)
            case "baseURL":
                if let literal = try? expressionParser.extractString(from: expr) {
                    baseURL = literal
                    isBaseURLLiteral = true
                } else {
                    baseURL = expressionParser.extractStringOrExpression(from: expr)
                    isBaseURLLiteral = false
                }
            case "path":
                path = try? expressionParser.extractString(from: expr)
            case "method":
                method = try? expressionParser.extractEnumCase(from: expr)
            default:
                break
            }
        }

        guard let responseType = responseType else {
            throw MacroError.missingRequiredArgument("response")
        }
        guard let baseURL = baseURL else {
            throw MacroError.missingRequiredArgument("baseURL")
        }
        guard let path = path else {
            throw MacroError.missingRequiredArgument("path")
        }
        guard let method = method else {
            throw MacroError.missingRequiredArgument("method")
        }

        let optionalPathParameters = pathParser.extractOptionalParameters(from: path)

        return MacroArguments(
            responseType: responseType,
            title: "",
            description: "",
            baseURL: baseURL,
            isBaseURLLiteral: isBaseURLLiteral,
            path: path,
            method: method,
            tags: [],
            optionalPathParameters: optionalPathParameters,
            testScenarios: [],
            errorExamples: [:],
            includeRetryTests: true,
            includePerformanceTests: false
        )
    }

    /// @APITestable의 인자를 파싱합니다.
    private static func parseAPITestableArguments(
        from node: AttributeSyntax,
        context _: some MacroExpansionContext
    ) throws -> TestableArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // 인자가 없으면 기본값 사용
            return TestableArguments(scenarios: [], errorExamples: [:])
        }

        var scenarios: [String] = []
        var errorExamples: [String: String] = [:]

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "scenarios":
                scenarios = extractTestScenariosInternal(from: expr)
            case "errorExamples":
                errorExamples = extractErrorExamplesInternal(from: expr)
            default:
                break
            }
        }

        return TestableArguments(scenarios: scenarios, errorExamples: errorExamples)
    }

    /// scenarios 배열을 파싱합니다.
    private static func extractTestScenariosInternal(from expr: ExprSyntax) -> [String] {
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

    /// errorExamples 딕셔너리를 파싱합니다.
    private static func extractErrorExamplesInternal(from expr: ExprSyntax) -> [String: String] {
        guard let dictExpr = expr.as(DictionaryExprSyntax.self) else {
            return [:]
        }

        var examples: [String: String] = [:]

        for element in dictExpr.content.as(DictionaryElementListSyntax.self) ?? [] {
            // Key (status code)
            guard let keyString = element.key.as(StringLiteralExprSyntax.self),
                  let keySegment = keyString.segments.first?.as(StringSegmentSyntax.self)
            else {
                continue
            }
            let key = keySegment.content.text

            // Value (JSON)
            if let valueString = element.value.as(StringLiteralExprSyntax.self) {
                var json = ""
                for segment in valueString.segments {
                    if let stringSegment = segment.as(StringSegmentSyntax.self) {
                        json += stringSegment.content.text
                    }
                }
                examples[key] = json
            }
        }

        return examples
    }

    /// 기존 멤버를 수집합니다.
    private static func collectExistingMembers(
        from structDecl: StructDeclSyntax
    ) -> Set<String> {
        var members: Set<String> = []

        for member in structDecl.memberBlock.members {
            // 변수/상수
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        members.insert(identifier.identifier.text)
                    }
                }
            }

            // 함수
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                members.insert(functionDecl.name.text)
            }

            // enum
            if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                members.insert(enumDecl.name.text)
            }
        }

        return members
    }

    /// MockScenario enum 생성 (기존 코드 재사용)
    private static func generateMockScenarioEnum(
        scenarios: [String],
        errorExamples: [String: String]
    ) -> DeclSyntax {
        // errorExamples 기반으로 필요한 케이스 결정
        var requiredScenarios: Set<String> = ["success"]

        // errorExamples에서 시나리오 추출
        for statusCode in errorExamples.keys {
            let caseName = getCaseNameForStatusCode(statusCode)
            requiredScenarios.insert(caseName)
        }

        // 사용자 정의 시나리오 추가
        for scenario in scenarios {
            requiredScenarios.insert(scenario)
        }

        let sortedScenarios = requiredScenarios.sorted()
        let cases = sortedScenarios.map { "case \($0)" }.joined(separator: "\n    ")

        return """
        /// Mock 테스트 시나리오
        enum MockScenario {
            \(raw: cases)
        }
        """
    }

    /// mockResponse() 메서드 생성 (개선된 버전)
    private static func generateMockResponseMethod(
        typeName _: String,
        responseType: String,
        scenarios: [String],
        errorExamples: [String: String]
    ) -> DeclSyntax {
        // 타입 문자열 정규화
        let trimmedType = responseType.trimmingCharacters(in: .whitespaces)

        // 배열 타입이거나 EmptyResponse인지 확인
        let isArrayType = trimmedType.hasPrefix("[") && trimmedType.hasSuffix("]") && !trimmedType.contains("?")
        let isEmptyResponse = trimmedType == "EmptyResponse"

        let fixtureCall: String
        if isEmptyResponse {
            fixtureCall = "let response = EmptyResponse()"
        } else if isArrayType {
            // 배열 타입일 경우, 내부 타입을 추출하여 fixture() 배열 생성
            let innerType = String(trimmedType.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)

            // 중첩 배열 체크
            if innerType.hasPrefix("[") {
                // 중첩 배열은 빈 배열로 처리
                fixtureCall = "let response: \(trimmedType) = []"
            } else {
                fixtureCall = "let response = [\(innerType).fixture()]"
            }
        } else {
            fixtureCall = "let response = \(trimmedType).fixture()"
        }

        var cases = """
        switch scenario {
            case .success:
                \(fixtureCall)
                let data = try? JSONEncoder().encode(response)
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
                return (data, httpResponse, nil)
        """

        // 생성할 케이스 추적 (중복 방지)
        var generatedCases: Set<String> = ["success"]

        // errorExamples 기반 에러 케이스 생성
        for (statusCode, json) in errorExamples.sorted(by: { $0.key < $1.key }) {
            let code = Int(statusCode) ?? 500
            let escaped = escapeJSON(json)
            let caseName = getCaseNameForStatusCode(statusCode)

            if generatedCases.contains(caseName) {
                continue
            }
            generatedCases.insert(caseName)

            cases += """

            case .\(caseName):
                let errorData = Data(\"\(escaped)\".utf8)
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: \(code),
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
                return (errorData, httpResponse, nil)
            """
        }

        // 사용자 정의 시나리오에 대한 기본 케이스 생성
        for scenario in scenarios {
            if generatedCases.contains(scenario) {
                continue
            }
            generatedCases.insert(scenario)

            switch scenario {
            case "networkError":
                cases += """

                case .networkError:
                    return (nil, nil, URLError(.notConnectedToInternet))
                """
            case "timeout":
                cases += """

                case .timeout:
                    return (nil, nil, URLError(.timedOut))
                """
            case "notFound":
                cases += """

                case .notFound:
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
            case "serverError":
                cases += """

                case .serverError:
                    let errorData = Data(\"\"\"
                    {
                        "error": "Internal Server Error",
                        "message": "Server encountered an error"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 500,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
                """
            case "unauthorized":
                cases += """

                case .unauthorized:
                    let errorData = Data(\"\"\"
                    {
                        "error": "Unauthorized",
                        "code": "UNAUTHORIZED"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
                """
            case "clientError":
                cases += """

                case .clientError:
                    let errorData = Data(\"\"\"
                    {
                        "error": "Validation Failed",
                        "message": "Request validation failed"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 400,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
                """
            case "forbidden":
                cases += """

                case .forbidden:
                    let errorData = Data(\"\"\"
                    {
                        "error": "Forbidden",
                        "code": "FORBIDDEN"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 403,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
                """
            case "tooManyRequests":
                cases += """

                case .tooManyRequests:
                    let errorData = Data(\"\"\"
                    {
                        "error": "Too Many Requests",
                        "message": "Rate limit exceeded"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 429,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
                """
            case "serviceUnavailable":
                cases += """

                case .serviceUnavailable:
                    let errorData = Data(\"\"\"
                    {
                        "error": "Service Unavailable",
                        "message": "Service is temporarily unavailable"
                    }
                    \"\"\".utf8)
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 503,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                    return (errorData, httpResponse, nil)
                """
            default:
                cases += """

                case .\(scenario):
                    let httpResponse = HTTPURLResponse(
                        url: url,
                        statusCode: 500,
                        httpVersion: nil,
                        headerFields: nil
                    )
                    return (nil, httpResponse, nil)
                """
            }
        }

        cases += """

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

    /// 상태 코드에 해당하는 케이스 이름 반환 (개선된 버전)
    private static func getCaseNameForStatusCode(_ statusCode: String) -> String {
        guard let code = Int(statusCode) else {
            return "invalidStatusCode"
        }

        switch code {
        case 200 ... 299:
            return "success"
        case 400:
            return "clientError"
        case 401:
            return "unauthorized"
        case 403:
            return "forbidden"
        case 404:
            return "notFound"
        case 429:
            return "tooManyRequests"
        case 500:
            return "serverError"
        case 502:
            return "badGateway"
        case 503:
            return "serviceUnavailable"
        case 504:
            return "gatewayTimeout"
        default:
            if code >= 400 && code < 500 {
                return "clientError"
            } else if code >= 500 {
                return "serverError"
            }
            return "unexpectedStatusCode"
        }
    }

    /// JSON escape 처리 (개선된 버전)
    private static func escapeJSON(_ json: String) -> String {
        return json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\u{08}", with: "\\b") // Backspace
            .replacingOccurrences(of: "\u{0C}", with: "\\f") // Form feed
    }
}
