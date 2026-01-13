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

        return try parseArguments(arguments)
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
                scenarios = extractTestScenarios(from: expr)
            case "errorExamples":
                errorExamples = extractErrorExamples(from: expr)
            default:
                break
            }
        }

        return TestableArguments(scenarios: scenarios, errorExamples: errorExamples)
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

    /// mockResponse() 메서드 생성 (기존 코드 재사용)
    private static func generateMockResponseMethod(
        typeName _: String,
        responseType: String,
        scenarios: [String],
        errorExamples: [String: String]
    ) -> DeclSyntax {
        // 배열 타입이거나 EmptyResponse인지 확인
        let isArrayType = responseType.hasPrefix("[") && responseType.hasSuffix("]")
        let isEmptyResponse = responseType == "EmptyResponse"

        let fixtureCall: String
        if isEmptyResponse {
            fixtureCall = "let response = EmptyResponse()"
        } else if isArrayType {
            // 배열 타입일 경우, 내부 타입을 추출하여 fixture() 배열 생성
            let innerType = String(responseType.dropFirst().dropLast())
            fixtureCall = "let response = [\(innerType).fixture()]"
        } else {
            fixtureCall = "let response = \(responseType).fixture()"
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

    /// 상태 코드에 해당하는 케이스 이름 반환
    private static func getCaseNameForStatusCode(_ statusCode: String) -> String {
        switch statusCode {
        case "404": return "notFound"
        case "500": return "serverError"
        case "401": return "unauthorized"
        case "400": return "clientError"
        default: return "serverError"
        }
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
}

// MARK: - Supporting Types

struct TestableArguments {
    let scenarios: [String]
    let errorExamples: [String: String]
}
