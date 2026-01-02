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

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. 구조체 검증
        let structDecl = try validateStructDeclaration(declaration, node: node, context: context)

        // 2. 매크로 인자 파싱
        let args = try parseMacroArguments(from: node, context: context)

        // 3. 기존 프로퍼티 수집
        let existingProperties = collectExistingProperties(from: structDecl)

        // 4. 멤버 선언 생성
        return assembleMemberDeclarations(
            for: structDecl,
            args: args,
            existingProperties: existingProperties
        )
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

    // MARK: Validation

    /// 구조체 선언을 검증합니다.
    private static func validateStructDeclaration(
        _ declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> StructDeclSyntax {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIRequestMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            throw APIRequestMacroError.onlyApplicableToStruct
        }
        return structDecl
    }

    /// 매크로 인자를 파싱합니다.
    private static func parseMacroArguments(
        from node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> MacroArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIRequestMacroError.missingArguments
            )
            context.diagnose(diagnostic)
            throw APIRequestMacroError.missingArguments
        }

        do {
            return try parseArguments(arguments)
        } catch let error as APIRequestMacroError {
            let diagnostic = Diagnostic(
                node: node,
                message: error
            )
            context.diagnose(diagnostic)
            throw error
        }
    }

    // MARK: Member Assembly

    /// 모든 멤버 선언을 조합합니다.
    private static func assembleMemberDeclarations(
        for structDecl: StructDeclSyntax,
        args: MacroArguments,
        existingProperties: Set<String>
    ) -> [DeclSyntax] {
        var members: [DeclSyntax] = []

        // typealias Response 생성
        if let responseTypealias = generateTypealias(args: args, existingProperties: existingProperties) {
            members.append(responseTypealias)
        }

        // baseURLString 생성
        if let baseURLString = generateBaseURLString(args: args, existingProperties: existingProperties) {
            members.append(baseURLString)
        }

        // path 생성
        if let path = generatePath(args: args, existingProperties: existingProperties) {
            members.append(path)
        }

        // method 생성
        if let method = generateMethod(args: args, existingProperties: existingProperties) {
            members.append(method)
        }

        // headers 생성
        if let headers = generateHeaders(args: args, existingProperties: existingProperties) {
            members.append(headers)
        }

        // metadata 생성
        let metadata = generateMetadata(for: structDecl, args: args)
        members.append(metadata)

        return members
    }

    // MARK: Property Generation

    /// typealias Response를 생성합니다.
    private static func generateTypealias(
        args: MacroArguments,
        existingProperties: Set<String>
    ) -> DeclSyntax? {
        guard !existingProperties.contains("Response") else {
            return nil
        }

        return """
        typealias Response = \(raw: args.responseType)
        """
    }

    /// baseURLString 프로퍼티를 생성합니다.
    private static func generateBaseURLString(
        args: MacroArguments,
        existingProperties: Set<String>
    ) -> DeclSyntax? {
        guard !existingProperties.contains("baseURLString"),
              let baseURL = args.baseURL
        else {
            return nil
        }

        if args.isBaseURLLiteral {
            // 문자열 리터럴인 경우
            return """
            var baseURLString: String {
                "\(raw: baseURL)"
            }
            """
        } else {
            // 표현식인 경우
            return """
            var baseURLString: String {
                \(raw: baseURL)
            }
            """
        }
    }

    /// path 프로퍼티를 생성합니다.
    private static func generatePath(
        args: MacroArguments,
        existingProperties: Set<String>
    ) -> DeclSyntax? {
        guard !existingProperties.contains("path") else {
            return nil
        }

        return """
        var path: String {
            "\(raw: args.path)"
        }
        """
    }

    /// method 프로퍼티를 생성합니다.
    private static func generateMethod(
        args: MacroArguments,
        existingProperties: Set<String>
    ) -> DeclSyntax? {
        guard !existingProperties.contains("method") else {
            return nil
        }

        return """
        var method: HTTPMethod {
            .\(raw: args.method)
        }
        """
    }

    /// headers 프로퍼티를 생성합니다.
    private static func generateHeaders(
        args: MacroArguments,
        existingProperties: Set<String>
    ) -> DeclSyntax? {
        guard !existingProperties.contains("headers"),
              !args.headers.isEmpty
        else {
            return nil
        }

        let headersDict = args.headers
            .map { "\"\($0.key)\": \"\($0.value)\"" }
            .joined(separator: ", ")

        return """
        var headers: [String: String]? {
            [\(raw: headersDict)]
        }
        """
    }

    // MARK: Metadata Generation

    /// metadata 프로퍼티를 생성합니다.
    private static func generateMetadata(
        for structDecl: StructDeclSyntax,
        args: MacroArguments
    ) -> DeclSyntax {
        let structName = structDecl.name.text
        let parameters = scanPropertyWrappers(from: structDecl)
        let parametersArray = generateParametersArray(parameters)

        // Property wrapper에서 헤더 정보 추출
        let allHeaders = collectAllHeaders(from: parameters, macroHeaders: args.headers)
        let headersCode = generateHeadersCode(allHeaders)

        // RequestBody 처리
        let requestBodyCodes = processRequestBody(from: parameters, args: args)

        // Response 처리
        let responseCodes = processResponse(args: args)

        // baseURLString 처리
        let baseURLStringCode = processBaseURLString(args: args)

        return """
        static var metadata: EndpointMetadata {
            EndpointMetadata(
                id: "\(raw: structName)",
                title: "\(raw: args.title)",
                description: "\(raw: args.description)",
                method: "\(raw: args.method)",
                path: "\(raw: args.path)",
                baseURLString: \(raw: baseURLStringCode),
                headers: \(raw: headersCode),
                tags: [\(raw: args.tags.map { "\"\($0)\"" }.joined(separator: ", "))],
                parameters: \(raw: parametersArray),
                requestBodyExample: \(raw: requestBodyCodes.example),
                requestBodyStructure: \(raw: requestBodyCodes.structure),
                requestBodyRelatedTypes: \(raw: requestBodyCodes.relatedTypes),
                responseStructure: \(raw: responseCodes.structure),
                responseExample: \(raw: responseCodes.example),
                responseTypeName: "\(raw: args.responseType)",
                relatedTypes: \(raw: responseCodes.relatedTypes)
            )
        }
        """
    }

    // MARK: Header Processing

    /// Property wrapper와 매크로 인자에서 모든 헤더를 수집합니다.
    private static func collectAllHeaders(
        from parameters: [PropertyWrapperInfo],
        macroHeaders: [String: String]
    ) -> [String: String] {
        var allHeaders = macroHeaders

        let headerParameters = parameters.filter {
            ["HeaderField", "CustomHeader"].contains($0.wrapperType)
        }

        for headerParam in headerParameters {
            guard let headerKey = headerParam.headerKey,
                  let defaultValue = headerParam.defaultValue
            else {
                continue
            }

            // 기본값이 있는 헤더만 메타데이터에 포함 (런타임 함수 호출 제외)
            if !defaultValue.contains("("), !defaultValue.contains(")") {
                allHeaders[headerKey] = defaultValue
            }
        }

        return allHeaders
    }

    /// 헤더 딕셔너리를 코드 문자열로 변환합니다.
    private static func generateHeadersCode(_ headers: [String: String]) -> String {
        guard !headers.isEmpty else {
            return "nil"
        }

        return "[\(headers.map { "\"\($0.key)\": \"\($0.value)\"" }.joined(separator: ", "))]"
    }

    // MARK: RequestBody Processing

    /// RequestBody 처리 결과
    private struct RequestBodyCodes {
        let example: String
        let structure: String
        let relatedTypes: String
    }

    /// RequestBody를 처리합니다.
    private static func processRequestBody(
        from parameters: [PropertyWrapperInfo],
        args: MacroArguments
    ) -> RequestBodyCodes {
        let requestBodyParameter = parameters.first { $0.wrapperType == "RequestBody" }

        if let requestBodyParam = requestBodyParameter {
            return processRequestBodyFromWrapper(requestBodyParam, args: args)
        } else if let example = args.requestBodyExample {
            return processRequestBodyFromExample(example)
        } else {
            return RequestBodyCodes(
                example: "nil",
                structure: "nil",
                relatedTypes: "nil"
            )
        }
    }

    /// Property wrapper에서 RequestBody를 처리합니다.
    private static func processRequestBodyFromWrapper(
        _ requestBodyParam: PropertyWrapperInfo,
        args: MacroArguments
    ) -> RequestBodyCodes {
        // 제네릭 타입 추출 (예: RequestBody<PostBody> -> PostBody)
        let requestBodyType = extractGenericType(from: requestBodyParam.type) ?? requestBodyParam.type

        // 옵셔널 제거 (예: PostBody? -> PostBody)
        let cleanType = requestBodyType.replacingOccurrences(of: "?", with: "")

        let structure = "resolveTypeStructure(for: \(cleanType).self)"
        let relatedTypes = "collectRelatedTypes(for: \(cleanType).self)"

        let example: String
        if let exampleString = args.requestBodyExample {
            example = escapeJSONString(exampleString)
        } else {
            example = "nil"
        }

        return RequestBodyCodes(
            example: example,
            structure: structure,
            relatedTypes: relatedTypes
        )
    }

    /// 예제 JSON에서 RequestBody를 처리합니다 (레거시).
    private static func processRequestBodyFromExample(_ example: String) -> RequestBodyCodes {
        let escaped = escapeJSONString(example)

        return RequestBodyCodes(
            example: escaped,
            structure: "generateStructureFromJSON(\(escaped))",
            relatedTypes: "[:]"
        )
    }

    // MARK: Response Processing

    /// Response 처리 결과
    private struct ResponseCodes {
        let structure: String
        let example: String
        let relatedTypes: String
    }

    /// Response를 처리합니다.
    private static func processResponse(args: MacroArguments) -> ResponseCodes {
        let structure = "resolveTypeStructure(for: \(args.responseType).self)"
        let relatedTypes = "collectRelatedTypes(for: \(args.responseType).self)"

        let example: String
        if let exampleString = args.responseExample {
            example = escapeJSONString(exampleString)
        } else {
            example = "nil"
        }

        return ResponseCodes(
            structure: structure,
            example: example,
            relatedTypes: relatedTypes
        )
    }

    // MARK: BaseURL Processing

    /// baseURLString을 처리합니다.
    private static func processBaseURLString(args: MacroArguments) -> String {
        guard let baseURL = args.baseURL else {
            return "\"https://example.com\""
        }

        if args.isBaseURLLiteral {
            return "\"\(baseURL)\""
        } else {
            return baseURL
        }
    }

    // MARK: Utility

    /// JSON 문자열을 이스케이프합니다.
    private static func escapeJSONString(_ string: String) -> String {
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

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
           let endIndex = typeString.lastIndex(of: ">") {
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
        DocumentedTypeMacroImpl.self
    ]
}
