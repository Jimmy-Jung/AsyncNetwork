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

// MARK: - PropertyWrapperSuggestion

/// PropertyWrapper 제안 진단 메시지
public struct PropertyWrapperSuggestion: DiagnosticMessage {
    let propertyName: String
    let propertyType: String
    let suggestedWrapper: String
    let reason: String

    public var message: String {
        "Consider using '\(suggestedWrapper)' for '\(propertyName)': \(reason)"
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "PropertyWrapperSuggestion")
    }

    public var severity: DiagnosticSeverity {
        .warning
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

        // 4. PropertyWrapper 제안 진단
        emitPropertyWrapperSuggestions(for: structDecl, args: args, context: context)

        // 5. 멤버 선언 생성
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
        guard !existingProperties.contains("baseURLString") else {
            return nil
        }

        if args.isBaseURLLiteral {
            // 문자열 리터럴인 경우
            return """
            var baseURLString: String {
                "\(raw: args.baseURL)"
            }
            """
        } else {
            // 표현식인 경우
            return """
            var baseURLString: String {
                \(raw: args.baseURL)
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

        // 선택적 경로 파라미터가 없으면 정적 경로
        if args.optionalPathParameters.isEmpty {
            return """
            var path: String {
                "\(raw: args.path)"
            }
            """
        }

        // 선택적 경로 파라미터가 있으면 동적 경로 생성
        return generateDynamicPath(args: args)
    }

    /// 선택적 PathParameter를 포함한 동적 경로를 생성합니다.
    private static func generateDynamicPath(args: MacroArguments) -> DeclSyntax {
        let normalizedPath = normalizePath(args.path)
        let optionalParams = args.optionalPathParameters

        // 경로를 세그먼트로 분리
        let segments = normalizedPath.split(separator: "/").map(String.init)
        var pathBuildLogic = "var result = \"\""

        for segment in segments {
            if segment.hasPrefix("{") && segment.hasSuffix("}") {
                // 플레이스홀더 세그먼트
                let paramName = String(segment.dropFirst().dropLast())

                if optionalParams.contains(paramName) {
                    // 선택적 파라미터
                    pathBuildLogic += """

                            if let \(paramName) = self.\(paramName) {
                                result += "/\\(\(paramName))"
                            }
                    """
                } else {
                    // 필수 파라미터
                    pathBuildLogic += """

                            result += "/\\(self.\(paramName))"
                    """
                }
            } else {
                // 일반 세그먼트
                pathBuildLogic += """

                        result += "/\(segment)"
                """
            }
        }

        pathBuildLogic += """

                return result
        """

        return """
        var path: String {
            \(raw: pathBuildLogic)
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

    // MARK: Metadata Generation

    /// metadata 프로퍼티를 생성합니다.
    private static func generateMetadata(
        for structDecl: StructDeclSyntax,
        args: MacroArguments
    ) -> DeclSyntax {
        let structName = structDecl.name.text
        let parameters = scanPropertyWrappers(from: structDecl)
        let parametersArray = generateParametersArray(parameters)

        // Property wrapper에서 헤더 정보 추출 (HeaderField, CustomHeader만)
        let allHeaders = collectHeadersFromPropertyWrappers(from: parameters)
        let headersCode = generateHeadersCode(allHeaders)

        // RequestBody 처리
        let requestBodyCodes = processRequestBody(from: parameters, args: args)

        // Response 처리
        let responseCodes = processResponse(args: args)

        // baseURLString 처리
        let baseURLStringCode = processBaseURLString(args: args)

        // Response 타입 자동 등록을 위한 코드 생성
        let responseRegistration = generateTypeRegistration(for: args.responseType)

        // RequestBody 타입 자동 등록을 위한 코드 생성
        let requestBodyParameter = parameters.first { $0.wrapperType == "RequestBody" }
        let requestBodyRegistration: String
        if let requestBodyParam = requestBodyParameter {
            let requestBodyType = extractGenericType(from: requestBodyParam.type) ?? requestBodyParam.type
            let cleanType = requestBodyType.replacingOccurrences(of: "?", with: "")
            requestBodyRegistration = generateTypeRegistration(for: cleanType)
        } else {
            requestBodyRegistration = ""
        }

        // 등록 코드가 있는 경우에만 포함
        let registrationCode: String
        if responseRegistration.isEmpty && requestBodyRegistration.isEmpty {
            registrationCode = ""
        } else {
            var lines: [String] = []
            if !responseRegistration.isEmpty {
                lines.append("// Response 타입 자동 등록")
                lines.append(responseRegistration)
            }
            if !requestBodyRegistration.isEmpty {
                lines.append("// RequestBody 타입 자동 등록")
                lines.append(requestBodyRegistration)
            }
            registrationCode = lines.joined(separator: "\n            ") + "\n            "
        }

        return """
        static var metadata: EndpointMetadata {
            \(raw: registrationCode)return EndpointMetadata(
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

    /// 타입 등록 코드를 생성합니다 (배열 및 옵셔널 타입 안전하게 처리).
    private static func generateTypeRegistration(for typeString: String) -> String {
        // 배열 타입 체크: [Post].self -> Post.self
        let cleanType = extractElementType(from: typeString)

        // EmptyResponse 같은 특수 타입은 스킵
        if cleanType == "EmptyResponse" || cleanType == "Void" {
            return ""
        }

        // 프리미티브 타입은 스킵
        if isPrimitiveResponseType(cleanType) {
            return ""
        }

        return "_ = \(cleanType).typeStructure"
    }

    /// 배열이나 옵셔널 타입에서 요소 타입을 추출합니다.
    /// 예: [Post].self -> Post, Post?.self -> Post, [Post]?.self -> Post
    private static func extractElementType(from typeString: String) -> String {
        var result = typeString

        // .self 제거
        result = result.replacingOccurrences(of: ".self", with: "")

        // 옵셔널 제거
        result = result.replacingOccurrences(of: "?", with: "")

        // 배열 체크: [Post] -> Post
        if result.hasPrefix("["), result.hasSuffix("]") {
            result = String(result.dropFirst().dropLast())
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Response 타입으로 사용되는 프리미티브 타입인지 확인
    private static func isPrimitiveResponseType(_ type: String) -> Bool {
        let primitives = [
            "Int", "String", "Double", "Bool", "Float",
            "Int64", "Int32", "UInt", "Date", "Data", "URL",
            "Void", "EmptyResponse",
        ]
        return primitives.contains(type)
    }

    // MARK: Header Processing

    /// Property wrapper에서 헤더 정보를 수집합니다 (HeaderField, CustomHeader만).
    private static func collectHeadersFromPropertyWrappers(
        from parameters: [PropertyWrapperInfo]
    ) -> [String: String] {
        var allHeaders: [String: String] = [:]

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

        // collectRelatedTypes를 두 번 호출:
        // 1. 첫 번째 호출: 모든 중첩 타입을 등록하기 위해 typeStructure 접근 트리거
        // 2. 두 번째 호출: 등록된 타입들의 구조를 수집
        let relatedTypes = """
        ({
            // 먼저 모든 중첩 타입을 등록하기 위해 collectRelatedTypes를 한 번 호출
            _ = collectRelatedTypes(for: \(cleanType).self)
            // 이제 등록된 타입들의 구조를 수집
            return collectRelatedTypes(for: \(cleanType).self)
        })()
        """

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

        // collectRelatedTypes를 두 번 호출:
        // 1. 첫 번째 호출: 모든 중첩 타입을 등록하기 위해 typeStructure 접근 트리거
        // 2. 두 번째 호출: 등록된 타입들의 구조를 수집
        let relatedTypes = """
        ({
            // 먼저 모든 중첩 타입을 등록하기 위해 collectRelatedTypes를 한 번 호출
            _ = collectRelatedTypes(for: \(args.responseType).self)
            // 이제 등록된 타입들의 구조를 수집
            return collectRelatedTypes(for: \(args.responseType).self)
        })()
        """

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
        if args.isBaseURLLiteral {
            return "\"\(args.baseURL)\""
        } else {
            return args.baseURL
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
           let endIndex = typeString.lastIndex(of: ">")
        {
            let innerType = String(typeString[typeString.index(after: startIndex) ..< endIndex])
            return innerType.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    // MARK: - Property Wrapper Suggestions

    /// PropertyWrapper 제안 진단을 생성합니다.
    private static func emitPropertyWrapperSuggestions(
        for structDecl: StructDeclSyntax,
        args: MacroArguments,
        context: some MacroExpansionContext
    ) {
        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // Property Wrapper 찾기
            var appliedWrapperType: String?
            for attribute in variableDecl.attributes {
                guard let customAttribute = attribute.as(AttributeSyntax.self) else {
                    continue
                }
                let name = customAttribute.attributeName.trimmedDescription
                if ["QueryParameter", "PathParameter", "HeaderField", "CustomHeader", "RequestBody", "FormData"].contains(name) {
                    appliedWrapperType = name
                    break
                }
            }

            // 생성된 프로퍼티는 건너뛰기 (Response, baseURLString, path, method 등)
            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                let propertyName = pattern.identifier.text

                // 생성된 프로퍼티는 체크하지 않음
                if ["baseURLString", "path", "method", "headers", "timeout"].contains(propertyName) {
                    continue
                }

                // 타입 추출
                guard let typeAnnotation = binding.typeAnnotation else {
                    continue
                }

                let typeString = typeAnnotation.type.trimmedDescription
                let isOptional = typeString.hasSuffix("?")

                // Property Wrapper가 이미 적용된 경우 유효성 검증
                if let wrapperType = appliedWrapperType {
                    if let validation = validatePropertyWrapper(
                        wrapperType: wrapperType,
                        propertyName: propertyName,
                        typeString: typeString,
                        isOptional: isOptional,
                        httpMethod: args.method,
                        path: args.path,
                        optionalPathParameters: args.optionalPathParameters
                    ) {
                        let diagnostic = Diagnostic(
                            node: variableDecl,
                            message: validation
                        )
                        context.diagnose(diagnostic)
                    }
                } else {
                    // Property Wrapper가 없는 경우 제안 생성
                    if let suggestion = suggestPropertyWrapper(
                        propertyName: propertyName,
                        typeString: typeString,
                        httpMethod: args.method,
                        path: args.path
                    ) {
                        let diagnostic = Diagnostic(
                            node: variableDecl,
                            message: suggestion
                        )
                        context.diagnose(diagnostic)
                    }
                }
            }
        }
    }

    /// Property Wrapper 사용의 유효성을 검증합니다.
    private static func validatePropertyWrapper(
        wrapperType: String,
        propertyName: String,
        typeString: String,
        isOptional: Bool,
        httpMethod: String,
        path: String,
        optionalPathParameters: Set<String>
    ) -> PropertyWrapperSuggestion? {
        switch wrapperType {
        case "PathParameter":
            return validatePathParameter(
                propertyName: propertyName,
                typeString: typeString,
                isOptional: isOptional,
                path: path,
                optionalPathParameters: optionalPathParameters
            )
        case "QueryParameter":
            return validateQueryParameter(
                propertyName: propertyName,
                typeString: typeString,
                httpMethod: httpMethod
            )
        case "RequestBody":
            return validateRequestBody(
                typeString: typeString,
                httpMethod: httpMethod
            )
        default:
            return nil
        }
    }

    /// PathParameter 사용의 유효성을 검증합니다.
    private static func validatePathParameter(
        propertyName: String,
        typeString: String,
        isOptional: Bool,
        path: String,
        optionalPathParameters: Set<String>
    ) -> PropertyWrapperSuggestion? {
        // 정규화된 경로에서 플레이스홀더 추출 (? 제거)
        let normalizedPath = normalizePath(path)
        let placeholders = extractPathPlaceholders(from: normalizedPath)

        // 1. PathParameter 옵셔널 검증
        // {id?} 형태면 옵셔널 허용, {id} 형태면 필수
        if isOptional, !optionalPathParameters.contains(propertyName) {
            return PropertyWrapperSuggestion(
                propertyName: propertyName,
                propertyType: typeString,
                suggestedWrapper: "@PathParameter",
                reason: "PathParameter는 필수값이어야 합니다. 타입을 '\(typeString.replacingOccurrences(of: "?", with: ""))'로 변경하거나 경로를 '/.../{{\(propertyName)?}'로 변경하세요"
            )
        }

        // 2. 프로퍼티 이름이 경로의 플레이스홀더와 일치하는지 확인
        if !placeholders.contains(propertyName) {
            // 유사한 플레이스홀더 찾기
            if let matchedPlaceholder = placeholders.first(where: { isSimilarName(propertyName, $0) }) {
                return PropertyWrapperSuggestion(
                    propertyName: propertyName,
                    propertyType: typeString,
                    suggestedWrapper: "@PathParameter(key: \"\(matchedPlaceholder)\")",
                    reason: "경로에 {\(matchedPlaceholder)}가 있습니다. @PathParameter(key: \"\(matchedPlaceholder)\")를 사용하거나 프로퍼티 이름을 '\(matchedPlaceholder)'로 변경하세요"
                )
            } else if !placeholders.isEmpty {
                return PropertyWrapperSuggestion(
                    propertyName: propertyName,
                    propertyType: typeString,
                    suggestedWrapper: "@PathParameter",
                    reason: "경로의 플레이스홀더[\(placeholders.joined(separator: ", "))]와 프로퍼티 이름이 일치하지 않습니다"
                )
            }
        }

        return nil
    }

    /// QueryParameter 사용의 유효성을 검증합니다.
    private static func validateQueryParameter(
        propertyName: String,
        typeString: String,
        httpMethod: String
    ) -> PropertyWrapperSuggestion? {
        // POST/PUT/PATCH의 바디 키워드가 있는 프로퍼티는 QueryParameter가 아닐 가능성
        if ["post", "put", "patch"].contains(httpMethod.lowercased()) {
            let bodyKeywords = ["body", "payload", "data", "request"]
            if bodyKeywords.contains(where: { propertyName.lowercased().contains($0) }) {
                return PropertyWrapperSuggestion(
                    propertyName: propertyName,
                    propertyType: typeString,
                    suggestedWrapper: "@RequestBody",
                    reason: "'\(propertyName)'는 요청 바디로 보입니다. @RequestBody 사용을 고려하세요"
                )
            }
        }

        return nil
    }

    /// RequestBody 사용의 유효성을 검증합니다.
    private static func validateRequestBody(
        typeString: String,
        httpMethod: String
    ) -> PropertyWrapperSuggestion? {
        // GET/DELETE 메서드에서는 RequestBody를 사용하면 안 됨
        if ["get", "delete"].contains(httpMethod.lowercased()) {
            return PropertyWrapperSuggestion(
                propertyName: "body",
                propertyType: typeString,
                suggestedWrapper: "@QueryParameter",
                reason: "\(httpMethod.uppercased()) 메서드에서는 RequestBody를 사용할 수 없습니다"
            )
        }

        return nil
    }

    /// 프로퍼티 이름과 타입을 기반으로 적절한 PropertyWrapper를 제안합니다.
    private static func suggestPropertyWrapper(
        propertyName: String,
        typeString: String,
        httpMethod: String,
        path: String
    ) -> PropertyWrapperSuggestion? {
        let lowercasedName = propertyName.lowercased()
        let isOptional = typeString.hasSuffix("?")

        // 1. HeaderField 제안
        if isHeaderRelated(propertyName: lowercasedName) {
            return PropertyWrapperSuggestion(
                propertyName: propertyName,
                propertyType: typeString,
                suggestedWrapper: "@HeaderField(key: .\(lowercasedName)) or @CustomHeader(\"\(propertyName)\")",
                reason: "HTTP 헤더는 @HeaderField 또는 @CustomHeader를 사용하세요"
            )
        }

        // 2. PathParameter 제안 (개선된 로직)
        if let matchedPlaceholder = findMatchingPathPlaceholder(propertyName: propertyName, path: path) {
            let suggestion = matchedPlaceholder == propertyName
                ? "@PathParameter"
                : "@PathParameter(key: \"\(matchedPlaceholder)\")"

            let reason = matchedPlaceholder == propertyName
                ? "경로에 {\(matchedPlaceholder)}가 있으므로 @PathParameter를 사용하세요"
                : "경로에 {\(matchedPlaceholder)}가 있습니다. @PathParameter(key: \"\(matchedPlaceholder)\")를 사용하거나 프로퍼티 이름을 '\(matchedPlaceholder)'로 변경하세요"

            return PropertyWrapperSuggestion(
                propertyName: propertyName,
                propertyType: typeString,
                suggestedWrapper: suggestion,
                reason: reason
            )
        }

        // 3. RequestBody 제안
        if isBodyRelated(propertyName: lowercasedName, httpMethod: httpMethod) {
            return PropertyWrapperSuggestion(
                propertyName: propertyName,
                propertyType: typeString,
                suggestedWrapper: "@RequestBody",
                reason: "요청 바디는 @RequestBody를 사용하세요"
            )
        }

        // 4. QueryParameter 제안 (기본값: GET 메서드의 일반 프로퍼티)
        if httpMethod.lowercased() == "get", isOptional {
            return PropertyWrapperSuggestion(
                propertyName: propertyName,
                propertyType: typeString,
                suggestedWrapper: "@QueryParameter",
                reason: "GET 메서드의 옵셔널 파라미터는 @QueryParameter를 사용하세요"
            )
        }

        // 5. 일반 프로퍼티에 대한 제안
        if isOptional {
            return PropertyWrapperSuggestion(
                propertyName: propertyName,
                propertyType: typeString,
                suggestedWrapper: "@QueryParameter",
                reason: "URL 쿼리 파라미터로 사용하려면 @QueryParameter를 추가하세요"
            )
        }

        return nil
    }

    /// 경로에서 플레이스홀더를 추출하고 프로퍼티 이름과 매칭합니다.
    private static func findMatchingPathPlaceholder(propertyName: String, path: String) -> String? {
        // 경로에서 모든 플레이스홀더 추출 (예: /posts/{id}/comments/{commentId})
        let placeholders = extractPathPlaceholders(from: path)

        // 1. 정확히 일치하는 플레이스홀더 찾기
        if placeholders.contains(propertyName) {
            return propertyName
        }

        // 2. 유사한 이름 찾기 (Levenshtein 거리 기반)
        for placeholder in placeholders {
            if isSimilarName(propertyName, placeholder) {
                return placeholder
            }
        }

        return nil
    }

    /// 경로에서 모든 플레이스홀더를 추출합니다.
    /// 예: "/posts/{id}/comments/{commentId}" -> ["id", "commentId"]
    private static func extractPathPlaceholders(from path: String) -> [String] {
        var placeholders: [String] = []
        var current = ""
        var inPlaceholder = false

        for char in path {
            if char == "{" {
                inPlaceholder = true
                current = ""
            } else if char == "}" {
                if inPlaceholder, !current.isEmpty {
                    placeholders.append(current)
                }
                inPlaceholder = false
                current = ""
            } else if inPlaceholder {
                current.append(char)
            }
        }

        return placeholders
    }

    /// 두 이름이 유사한지 확인합니다 (오타, 복수형, 언더스코어/캐멀케이스 차이 등).
    private static func isSimilarName(_ name1: String, _ name2: String) -> Bool {
        let lower1 = name1.lowercased()
        let lower2 = name2.lowercased()

        // 1. 정확히 일치
        if lower1 == lower2 {
            return true
        }

        // 2. 복수형 체크 (ids <-> id, users <-> user)
        if lower1 == lower2 + "s" || lower2 == lower1 + "s" {
            return true
        }

        // 3. 언더스코어 vs 캐멀케이스 (user_id <-> userId)
        let normalized1 = lower1.replacingOccurrences(of: "_", with: "")
        let normalized2 = lower2.replacingOccurrences(of: "_", with: "")
        if normalized1 == normalized2 {
            return true
        }

        // 4. Levenshtein 거리가 2 이하 (오타 허용)
        if levenshteinDistance(lower1, lower2) <= 2 {
            return true
        }

        return false
    }

    /// Levenshtein 거리 계산 (편집 거리)
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        // 빈 문자열 처리
        if m == 0 { return n }
        if n == 0 { return m }

        // DP 테이블
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        // 초기화
        for i in 0 ... m {
            dp[i][0] = i
        }
        for j in 0 ... n {
            dp[0][j] = j
        }

        // DP 계산
        for i in 1 ... m {
            for j in 1 ... n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1, // 삭제
                    dp[i][j - 1] + 1, // 삽입
                    dp[i - 1][j - 1] + cost // 치환
                )
            }
        }

        return dp[m][n]
    }

    /// 헤더 관련 프로퍼티인지 확인
    private static func isHeaderRelated(propertyName: String) -> Bool {
        let headerKeywords = [
            "authorization", "auth", "token",
            "contenttype", "content",
            "useragent", "agent",
            "accept", "language",
            "cookie", "session",
            "apikey", "key",
            "bearer", "basic",
        ]

        return headerKeywords.contains { propertyName.contains($0) }
    }

    /// 요청 바디 관련 프로퍼티인지 확인
    private static func isBodyRelated(propertyName: String, httpMethod: String) -> Bool {
        let bodyKeywords = ["body", "payload", "data", "request"]
        let hasBodyKeyword = bodyKeywords.contains { propertyName.contains($0) }

        // POST, PUT, PATCH 메서드는 바디를 자주 사용
        let isBodyMethod = ["post", "put", "patch"].contains(httpMethod.lowercased())

        return hasBodyKeyword || (isBodyMethod && propertyName.count > 3)
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
