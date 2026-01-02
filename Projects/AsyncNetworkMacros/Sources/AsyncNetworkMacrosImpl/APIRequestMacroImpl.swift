//
//  APIRequestMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/01.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - APIRequestMacroError

/// APIRequest 매크로 에러 타입
public enum APIRequestMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    case onlyApplicableToStruct
    case missingArguments
    case missingRequiredArgument(String)
    case invalidArgument(String)

    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@APIRequest can only be applied to a struct"
        case .missingArguments:
            return "@APIRequest requires arguments"
        case let .missingRequiredArgument(arg):
            return "@APIRequest missing required argument: \(arg)"
        case let .invalidArgument(arg):
            return "@APIRequest invalid argument: \(arg)"
        }
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "APIRequestMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - APIRequestMacroImpl

/// @APIRequest 매크로 구현
///
/// 이 매크로는 다음을 자동 생성합니다:
/// - typealias Response
/// - var baseURLString: String
/// - var path: String
/// - var method: HTTPMethod
/// - var headers: [String: String]?
/// - var task: HTTPTask
/// - static var metadata: EndpointMetadata
public struct APIRequestMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 구조체에만 적용 가능
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIRequestMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            return []
        }

        // 매크로 인자 파싱
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIRequestMacroError.missingArguments
            )
            context.diagnose(diagnostic)
            return []
        }

        let args: MacroArguments
        do {
            args = try parseArguments(arguments)
        } catch let error as APIRequestMacroError {
            let diagnostic = Diagnostic(
                node: node,
                message: error
            )
            context.diagnose(diagnostic)
            return []
        }

        // 이미 선언된 프로퍼티 이름 수집
        let existingProperties = collectExistingProperties(from: structDecl)

        var members: [DeclSyntax] = []

        // typealias Response 생성
        if !existingProperties.contains("Response") {
            members.append(
                """
                typealias Response = \(raw: args.responseType)
                """
            )
        }

        // baseURLString 생성 (옵셔널)
        if !existingProperties.contains("baseURLString"), let baseURL = args.baseURL {
            if args.isBaseURLLiteral {
                // 문자열 리터럴인 경우: 그대로 사용
                members.append(
                    """
                    var baseURLString: String {
                        "\(raw: baseURL)"
                    }
                    """
                )
            } else {
                // 표현식인 경우: 평가되도록 그대로 삽입
                members.append(
                    """
                    var baseURLString: String {
                        \(raw: baseURL)
                    }
                    """
                )
            }
        }

        // path 생성
        if !existingProperties.contains("path") {
            members.append(
                """
                var path: String {
                    "\(raw: args.path)"
                }
                """
            )
        }

        // method 생성
        if !existingProperties.contains("method") {
            members.append(
                """
                var method: HTTPMethod {
                    .\(raw: args.method)
                }
                """
            )
        }

        // headers 생성 (옵셔널)
        if !existingProperties.contains("headers"), !args.headers.isEmpty {
            let headersDict = args.headers.map { "\"\($0.key)\": \"\($0.value)\"" }.joined(separator: ", ")
            members.append(
                """
                var headers: [String: String]? {
                    [\(raw: headersDict)]
                }
                """
            )
        }

        // metadata 생성
        let structName = structDecl.name.text
        let parameters = scanPropertyWrappers(from: structDecl)
        let parametersArray = generateParametersArray(parameters)

        // Property wrapper에서 헤더 정보 추출
        let headerParameters = parameters.filter { ["HeaderField", "CustomHeader"].contains($0.wrapperType) }
        var allHeaders = args.headers // 매크로 인자로 전달된 정적 헤더
        for headerParam in headerParameters {
            if let headerKey = headerParam.headerKey, let defaultValue = headerParam.defaultValue {
                // 기본값이 있는 헤더만 메타데이터에 포함 (런타임 함수 호출 제외)
                if !defaultValue.contains("("), !defaultValue.contains(")") {
                    allHeaders[headerKey] = defaultValue
                }
            }
        }

        // @RequestBody에서 타입 정보 추출
        let requestBodyParameter = parameters.first { $0.wrapperType == "RequestBody" }

        // requestBodyStructure와 requestBodyRelatedTypes 생성
        let requestBodyExampleCode: String
        let requestBodyStructureCode: String
        let requestBodyRelatedTypesCode: String

        if let requestBodyParam = requestBodyParameter {
            // @RequestBody의 타입에서 제네릭 타입 추출 (예: RequestBody<PostBody> -> PostBody)
            let requestBodyType = extractGenericType(from: requestBodyParam.type) ?? requestBodyParam.type

            // 타입에서 옵셔널 제거 (예: PostBody? -> PostBody)
            let cleanType = requestBodyType.replacingOccurrences(of: "?", with: "")

            // @RequestBody의 타입에서 typeStructure 추출 (Response와 동일한 방식)
            requestBodyStructureCode = "resolveTypeStructure(for: \(cleanType).self)"

            // relatedTypes도 동일하게 수집
            requestBodyRelatedTypesCode = "collectRelatedTypes(for: \(cleanType).self)"

            // requestBodyExample은 매크로 인자에서 가져오거나 nil
            if let example = args.requestBodyExample {
                let escaped = example
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                requestBodyExampleCode = "\"\(escaped)\""
            } else {
                requestBodyExampleCode = "nil"
            }
        } else if let example = args.requestBodyExample {
            // @RequestBody가 없지만 requestBodyExample이 있는 경우 (레거시)
            let escaped = example
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            requestBodyExampleCode = "\"\(escaped)\""

            // JSON에서 구조 생성 (레거시)
            requestBodyStructureCode = "generateStructureFromJSON(\"\(escaped)\")"
            requestBodyRelatedTypesCode = "[:]"
        } else {
            requestBodyExampleCode = "nil"
            requestBodyStructureCode = "nil"
            requestBodyRelatedTypesCode = "nil"
        }

        // responseStructure 생성 (DocumentedType 프로토콜 체크는 런타임에 수행)
        // 매크로는 다른 타입의 정보에 접근할 수 없으므로 런타임에 조회하도록 코드 생성
        let responseStructureCode = "resolveTypeStructure(for: \(args.responseType).self)"

        // relatedTypes는 런타임에 collectRelatedTypes 헬퍼로 수집
        // Response 타입에서 시작하여 모든 중첩 타입을 BFS로 탐색
        let relatedTypesCode = "collectRelatedTypes(for: \(args.responseType).self)"

        let responseExampleCode: String
        if let example = args.responseExample {
            let escaped = example
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            responseExampleCode = "\"\(escaped)\""
        } else {
            responseExampleCode = "nil"
        }

        // baseURLString 처리
        let baseURLStringCode: String
        if let baseURL = args.baseURL {
            if args.isBaseURLLiteral {
                // 문자열 리터럴인 경우
                baseURLStringCode = "\"\(baseURL)\""
            } else {
                // 표현식인 경우: 런타임에 평가
                baseURLStringCode = baseURL
            }
        } else {
            // baseURL이 제공되지 않은 경우 기본값
            baseURLStringCode = "\"https://example.com\""
        }

        members.append(
            """
            static var metadata: EndpointMetadata {
                EndpointMetadata(
                    id: "\(raw: structName)",
                    title: "\(raw: args.title)",
                    description: "\(raw: args.description)",
                    method: "\(raw: args.method)",
                    path: "\(raw: args.path)",
                    baseURLString: \(raw: baseURLStringCode),
                    headers: \(raw: allHeaders.isEmpty ? "nil" : """
            [\(allHeaders.map { "\"\($0.key)\": \"\($0.value)\"" }.joined(separator: ", "))]
                    """),
                    tags: [\(raw: args.tags.map { "\"\($0)\"" }.joined(separator: ", "))],
                    parameters: \(raw: parametersArray),
                    requestBodyExample: \(raw: requestBodyExampleCode),
                    requestBodyStructure: \(raw: requestBodyStructureCode),
                    requestBodyRelatedTypes: \(raw: requestBodyRelatedTypesCode),
                    responseStructure: \(raw: responseStructureCode),
                    responseExample: \(raw: responseExampleCode),
                    responseTypeName: "\(raw: args.responseType)",
                    relatedTypes: \(raw: relatedTypesCode)
                )
            }
            """
        )

        return members
    }

    // MARK: - ExtensionMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // 구조체에만 적용 가능
        guard declaration.is(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIRequestMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            return []
        }

        // APIRequest 프로토콜 채택
        let ext: DeclSyntax =
            """
            extension \(type.trimmed): APIRequest {}
            """

        guard let extensionDeclSyntax = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Helper Methods

    /// 구조체에서 이미 선언된 프로퍼티/타입 이름을 수집합니다.
    private static func collectExistingProperties(
        from structDecl: StructDeclSyntax
    ) -> Set<String> {
        var properties: Set<String> = []

        for member in structDecl.memberBlock.members {
            // 변수/상수
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        properties.insert(identifier.identifier.text)
                    }
                }
            }

            // typealias
            if let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self) {
                properties.insert(typealiasDecl.name.text)
            }
        }

        return properties
    }

    /// 제네릭 타입에서 내부 타입을 추출합니다.
    /// 예: "RequestBody<PostBody>" -> "PostBody"
    ///     "[String: User]" -> "User"
    private static func extractGenericType(from typeString: String) -> String? {
        // RequestBody<PostBody> 형태에서 PostBody 추출
        if let startIndex = typeString.firstIndex(of: "<"),
           let endIndex = typeString.lastIndex(of: ">")
        {
            let innerType = String(typeString[typeString.index(after: startIndex) ..< endIndex])
            return innerType.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}

// MARK: - Plugin Registration

@main
struct AsyncNetworkMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIRequestMacroImpl.self,
        DocumentedTypeMacroImpl.self,
    ]
}
