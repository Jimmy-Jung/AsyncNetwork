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
///
/// 사용 예시:
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

        // 테스트 관련 멤버 생성 (testScenarios나 errorExamples가 있는 경우)
        if !args.testScenarios.isEmpty || !args.errorExamples.isEmpty {
            // MockScenario enum
            if !existingProperties.contains("MockScenario") {
                members.append(generateMockScenarioEnum(
                    scenarios: args.testScenarios,
                    errorExamples: args.errorExamples
                ))
            }

            // mockResponse() 메서드
            if !existingProperties.contains("mockResponse") {
                members.append(generateMockResponseMethod(
                    typeName: structDecl.name.text,
                    responseType: args.responseType,
                    scenarios: args.testScenarios,
                    errorExamples: args.errorExamples
                ))
            }
        }

        // memberwise initializer 생성
        if let initializer = generateMemberwiseInitializer(for: structDecl, existingProperties: existingProperties) {
            members.append(initializer)
        }

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

        // 경로에 플레이스홀더가 있는지 확인 (동적 경로 필요)
        let hasPlaceholders = args.path.contains("{") && args.path.contains("}")
        
        if hasPlaceholders {
            // 플레이스홀더가 있으면 동적 경로 생성
            return generateDynamicPath(args: args)
        } else {
            // 플레이스홀더가 없으면 정적 경로
            return """
            var path: String {
                "\(raw: args.path)"
            }
            """
        }
    }

    /// 선택적 PathParameter를 포함한 동적 경로를 생성합니다.
    private static func generateDynamicPath(args: MacroArguments) -> DeclSyntax {
        let normalizedPath = normalizePath(args.path)
        let optionalParams = args.optionalPathParameters

        // 경로를 세그먼트로 분리 (빈 문자열 제거)
        let segments = normalizedPath.split(separator: "/").map(String.init).filter { !$0.isEmpty }
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

            // initializer 확인
            if member.decl.is(InitializerDeclSyntax.self) {
                properties.insert("init")
            }
        }

        return properties
    }

    /// Memberwise initializer를 생성합니다.
    private static func generateMemberwiseInitializer(
        for structDecl: StructDeclSyntax,
        existingProperties: Set<String>
    ) -> DeclSyntax? {
        // 이미 init이 있으면 생성하지 않음
        if existingProperties.contains("init") {
            return nil
        }

        // 프로퍼티 정보 수집
        var propertyInfos: [(name: String, type: String, wrapperInfo: (type: String, key: String?)?, defaultValue: String?)] = []

        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // Property wrapper 확인 및 타입, 키 추출
            var wrapperInfo: (type: String, key: String?)?
            for attribute in variableDecl.attributes {
                guard let customAttribute = attribute.as(AttributeSyntax.self) else {
                    continue
                }
                let wrapperType = customAttribute.attributeName.trimmedDescription
                if ["QueryParameter", "PathParameter", "HeaderField", "CustomHeader", "RequestBody", "FormData"].contains(wrapperType) {
                    // key 파라미터 추출
                    var customKey: String?
                    if let arguments = customAttribute.arguments?.as(LabeledExprListSyntax.self) {
                        for argument in arguments {
                            if argument.label?.text == "key" {
                                customKey = argument.expression.trimmedDescription
                                break
                            }
                        }
                    }
                    wrapperInfo = (type: wrapperType, key: customKey)
                    break
                }
            }

            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation else {
                    continue
                }

                let propertyName = pattern.identifier.text
                let propertyType = typeAnnotation.type.trimmedDescription

                // 생성된 프로퍼티는 제외
                if ["baseURLString", "path", "method", "Response"].contains(propertyName) {
                    continue
                }

                // 기본값 추출
                var defaultValue: String?
                if let initializer = binding.initializer {
                    defaultValue = initializer.value.trimmedDescription
                }

                propertyInfos.append((
                    name: propertyName,
                    type: propertyType,
                    wrapperInfo: wrapperInfo,
                    defaultValue: defaultValue
                ))
            }
        }

        // 프로퍼티가 없으면 기본 init 생성
        if propertyInfos.isEmpty {
            return """
            public init() {}
            """
        }

        // 파라미터 생성
        let parameters = propertyInfos.map { info -> String in
            if let defaultValue = info.defaultValue {
                // 명시적 기본값이 있는 경우
                return "\(info.name): \(info.type) = \(defaultValue)"
            } else if info.type.hasSuffix("?") {
                // 옵셔널 타입인 경우 기본값을 nil로 설정
                return "\(info.name): \(info.type) = nil"
            } else {
                // 필수 파라미터
                return "\(info.name): \(info.type)"
            }
        }.joined(separator: ", ")

        // 본문 생성
        let assignments = propertyInfos.map { info -> String in
            if let wrapper = info.wrapperInfo {
                let isOptional = info.type.hasSuffix("?")
                
                // Property wrapper의 initializer를 직접 호출
                if let customKey = wrapper.key {
                    // 커스텀 키가 있는 경우
                    if wrapper.type == "QueryParameter" {
                        // QueryParameter는 non-optional과 optional 모두 지원
                        // 타입 캐스팅 없이 그대로 전달 (초기화자 오버로딩으로 처리)
                        return "self._\(info.name) = \(wrapper.type)(wrappedValue: \(info.name), key: \(customKey))"
                    } else {
                        // PathParameter 등 다른 wrapper는 그대로 전달
                        return "self._\(info.name) = \(wrapper.type)(wrappedValue: \(info.name), key: \(customKey))"
                    }
                } else {
                    // 키가 없는 경우
                    if wrapper.type == "QueryParameter" {
                        // QueryParameter는 non-optional과 optional 모두 지원
                        // 타입 캐스팅 없이 그대로 전달 (초기화자 오버로딩으로 처리)
                        return "self._\(info.name) = \(wrapper.type)(wrappedValue: \(info.name))"
                    } else {
                        return "self._\(info.name) = \(wrapper.type)(wrappedValue: \(info.name))"
                    }
                }
            } else {
                // 일반 프로퍼티
                return "self.\(info.name) = \(info.name)"
            }
        }.joined(separator: "\n        ")

        return """
        public init(\(raw: parameters)) {
            \(raw: assignments)
        }
        """
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
                isOptional: isOptional,
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
        isOptional: Bool,
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
        if httpMethod.lowercased() == "get" {
            if isOptional {
                return PropertyWrapperSuggestion(
                    propertyName: propertyName,
                    propertyType: typeString,
                    suggestedWrapper: "@QueryParameter",
                    reason: "GET 메서드의 파라미터는 @QueryParameter를 사용하세요 (optional이면 nil일 때 생략됨)"
                )
            }
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

    // MARK: - Test Scenario Generation

    /// MockScenario enum 생성
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
        
        // 기본 시나리오 추가 (사용자가 명시한 경우)
        let commonScenarios = ["networkError", "timeout", "notFound", "serverError", "unauthorized", "clientError"]
        for scenario in scenarios {
            if commonScenarios.contains(scenario) {
                requiredScenarios.insert(scenario)
            }
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

    /// mockResponse() 메서드 생성
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
            // EmptyResponse는 초기화자 사용
            fixtureCall = "let response = EmptyResponse()"
        } else if isArrayType {
            // 배열 타입의 경우 빈 배열 반환
            fixtureCall = "let response = \(responseType)()"
        } else {
            // 일반 타입의 경우 fixture() 메서드 호출
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
                continue // 이미 생성된 케이스는 스킵
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
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )
                return (nil, httpResponse, nil)
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
                    "error": "Bad Request",
                    "code": "BAD_REQUEST"
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
                // 알 수 없는 시나리오는 기본 에러 반환
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

// MARK: - Plugin Registration

@main
struct AsyncNetworkMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIRequestMacroImpl.self,
        TestableDTOMacroImpl.self,
        TestableSemerMacroImpl.self,
    ]
}
