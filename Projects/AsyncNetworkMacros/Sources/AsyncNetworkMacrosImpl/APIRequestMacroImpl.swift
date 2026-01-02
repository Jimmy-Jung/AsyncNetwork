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
public enum APIRequestMacroError: CustomStringConvertible, Error {
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
}

extension APIRequestMacroError: DiagnosticMessage {
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

        // task 생성 (기본값: .requestWithPropertyWrappers)
        if !existingProperties.contains("task") {
            members.append(
                """
                var task: HTTPTask {
                    .requestWithPropertyWrappers
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

        // responseStructure 생성
        let responseStructure = args.responseStructure ?? generateResponseStructure(from: args.responseType)

        // responseExample과 requestBodyExample, responseStructure를 raw string으로 변환
        let requestBodyExampleCode: String
        let requestBodyFieldsCode: String

        if let example = args.requestBodyExample {
            // 백슬래시와 따옴표를 이스케이프
            let escaped = example
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            requestBodyExampleCode = "\"\(escaped)\""

            // requestBodyExample에서 필드 파싱
            let fields = parseRequestBodyFields(from: example)
            let fieldsCodes = fields.map { field -> String in
                let exampleValueCode = field.exampleValue.map { "\"\($0)\"" } ?? "nil"
                return "RequestBodyFieldInfo(name: \"\(field.name)\", type: \"\(field.type)\", isRequired: \(field.isRequired), exampleValue: \(exampleValueCode))"
            }
            requestBodyFieldsCode = "[\(fieldsCodes.joined(separator: ", "))]"
        } else {
            requestBodyExampleCode = "nil"
            requestBodyFieldsCode = "[]"
        }

        let responseStructureCode: String
        if let structure = responseStructure {
            let escaped = structure
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            responseStructureCode = "\"\(escaped)\""
        } else {
            responseStructureCode = "nil"
        }

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
                    headers: \(raw: allHeaders.isEmpty ? "nil" : "[\(allHeaders.map { "\"\($0.key)\": \"\($0.value)\"" }.joined(separator: ", "))]"),
                    tags: [\(raw: args.tags.map { "\"\($0)\"" }.joined(separator: ", "))],
                    parameters: \(raw: parametersArray),
                    requestBodyExample: \(raw: requestBodyExampleCode),
                    requestBodyFields: \(raw: requestBodyFieldsCode),
                    responseStructure: \(raw: responseStructureCode),
                    responseExample: \(raw: responseExampleCode),
                    responseTypeName: "\(raw: args.responseType)"
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

    /// Property Wrapper를 스캔하여 파라미터 정보를 수집합니다.
    private static func scanPropertyWrappers(
        from structDecl: StructDeclSyntax
    ) -> [PropertyWrapperInfo] {
        var parameters: [PropertyWrapperInfo] = []

        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            for attribute in variableDecl.attributes {
                guard let customAttribute = attribute.as(AttributeSyntax.self),
                      let identifier = customAttribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                else {
                    continue
                }

                let wrapperType = identifier
                guard ["PathParameter", "QueryParameter", "HeaderParameter", "HeaderField", "CustomHeader"].contains(wrapperType) else {
                    continue
                }

                // 프로퍼티 이름 추출
                guard let binding = variableDecl.bindings.first,
                      let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
                else {
                    continue
                }
                let propertyName = pattern.identifier.text

                // 타입 추출
                let propertyType = extractPropertyType(from: binding) ?? "String"

                // 옵셔널 여부 확인
                let isOptional = propertyType.hasSuffix("?")

                // HeaderField, CustomHeader의 경우 헤더 키 추출
                var headerKey: String? = nil
                var defaultValue: String? = nil

                if wrapperType == "HeaderField" || wrapperType == "CustomHeader" {
                    // @HeaderField(.authorization) 또는 @CustomHeader("X-Custom-Header")에서 인자 추출
                    if let arguments = customAttribute.arguments?.as(LabeledExprListSyntax.self) {
                        for argument in arguments {
                            let expr = argument.expression
                            // HeaderField(.authorization) - enum case
                            if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                                let caseName = memberAccess.declName.baseName.text
                                // HTTPHeaders.HeaderKey enum case를 실제 헤더 이름으로 매핑
                                headerKey = mapHeaderKeyToString(caseName)
                            }
                            // CustomHeader("X-Custom-Header") - string literal
                            else if let stringLiteral = extractStringLiteral(from: expr) {
                                headerKey = stringLiteral
                            }
                        }
                    }

                    // 기본값 추출 (var userAgent: String? = "MyApp/1.0.0")
                    if let initializer = binding.initializer {
                        if let stringLiteral = extractStringLiteral(from: initializer.value) {
                            defaultValue = stringLiteral
                        } else if initializer.value.is(FunctionCallExprSyntax.self) {
                            // UUID().uuidString 같은 함수 호출은 "UUID()"로 표시
                            defaultValue = initializer.value.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }

                parameters.append(PropertyWrapperInfo(
                    name: propertyName,
                    type: propertyType,
                    wrapperType: wrapperType,
                    isRequired: !isOptional,
                    headerKey: headerKey,
                    defaultValue: defaultValue
                ))
            }
        }

        return parameters
    }

    /// Property의 타입을 추출합니다.
    private static func extractPropertyType(from binding: PatternBindingSyntax) -> String? {
        guard let typeAnnotation = binding.typeAnnotation else {
            return nil
        }
        return typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// HTTPHeaders.HeaderKey enum case를 실제 HTTP 헤더 이름으로 매핑합니다.
    private static func mapHeaderKeyToString(_ key: String) -> String {
        let mapping: [String: String] = [
            "contentType": "Content-Type",
            "accept": "Accept",
            "authorization": "Authorization",
            "userAgent": "User-Agent",
            "acceptLanguage": "Accept-Language",
            "appVersion": "X-App-Version",
            "deviceModel": "X-Device-Model",
            "osVersion": "X-OS-Version",
            "bundleId": "X-Bundle-Id",
            "requestId": "X-Request-Id",
            "timestamp": "X-Timestamp",
            "sessionId": "X-Session-Id",
            "clientVersion": "X-Client-Version",
            "platform": "X-Platform",
        ]
        return mapping[key] ?? key
    }

    /// PropertyWrapperInfo 배열을 ParameterInfo 배열 리터럴로 변환합니다.
    /// HeaderField와 CustomHeader는 제외합니다 (이들은 headers 프로퍼티로 처리됨)
    private static func generateParametersArray(_ parameters: [PropertyWrapperInfo]) -> String {
        // HeaderField와 CustomHeader는 파라미터가 아니므로 제외
        let filteredParameters = parameters.filter {
            !["HeaderField", "CustomHeader"].contains($0.wrapperType)
        }

        if filteredParameters.isEmpty {
            return "[]"
        }

        let parameterStrings = filteredParameters.map { param in
            let location: String
            switch param.wrapperType {
            case "PathParameter":
                location = ".path"
            case "QueryParameter":
                location = ".query"
            case "HeaderParameter":
                location = ".header"
            case "RequestBody":
                location = ".body"
            default:
                location = ".query"
            }

            return """
            ParameterInfo(
                        id: "\(param.name)",
                        name: "\(param.name)",
                        type: "\(param.type)",
                        location: \(location),
                        isRequired: \(param.isRequired)
                    )
            """
        }

        return """
        [
                    \(parameterStrings.joined(separator: ",\n                    "))
                ]
        """
    }
}

// MARK: - Helper Types

struct MacroArguments {
    let responseType: String
    let title: String
    let description: String
    let baseURL: String?
    let isBaseURLLiteral: Bool // baseURL이 문자열 리터럴인지 여부
    let path: String
    let method: String
    let headers: [String: String]
    let tags: [String]
    let requestBodyExample: String?
    let responseStructure: String?
    let responseExample: String?
}

struct PropertyWrapperInfo {
    let name: String
    let type: String
    let wrapperType: String
    let isRequired: Bool
    let headerKey: String? // HeaderField, CustomHeader용
    let defaultValue: String? // 기본값
}

// MARK: - Argument Parsing

func parseArguments(_ arguments: LabeledExprListSyntax) throws -> MacroArguments {
    var responseType: String?
    var title: String?
    var description = ""
    var baseURL: String?
    var isBaseURLLiteral = false
    var path: String?
    var method: String?
    var headers: [String: String] = [:]
    var tags: [String] = []
    var requestBodyExample: String?
    var responseStructure: String?
    var responseExample: String?

    for argument in arguments {
        let label = argument.label?.text ?? ""
        let expr = argument.expression

        switch label {
        case "response":
            responseType = extractTypeName(from: expr)
        case "title":
            title = extractStringLiteral(from: expr)
        case "description":
            description = extractStringLiteral(from: expr) ?? ""
        case "baseURL":
            // 문자열 리터럴인지 확인
            if let literal = extractStringLiteral(from: expr) {
                baseURL = literal
                isBaseURLLiteral = true
            } else if let expression = extractExpression(from: expr) {
                baseURL = expression
                isBaseURLLiteral = false
            }
        case "path":
            path = extractStringLiteral(from: expr)
        case "method":
            method = extractStringOrEnumCase(from: expr)
        case "headers":
            headers = extractDictionary(from: expr)
        case "tags":
            tags = extractArray(from: expr)
        case "requestBodyExample":
            requestBodyExample = extractStringLiteral(from: expr)
        case "responseStructure":
            responseStructure = extractStringLiteral(from: expr)
        case "responseExample":
            responseExample = extractStringLiteral(from: expr)
        default:
            break
        }
    }

    guard let responseType = responseType else {
        throw APIRequestMacroError.missingRequiredArgument("response")
    }
    guard let title = title else {
        throw APIRequestMacroError.missingRequiredArgument("title")
    }
    guard let path = path else {
        throw APIRequestMacroError.missingRequiredArgument("path")
    }
    guard let method = method else {
        throw APIRequestMacroError.missingRequiredArgument("method")
    }

    return MacroArguments(
        responseType: responseType,
        title: title,
        description: description,
        baseURL: baseURL,
        isBaseURLLiteral: isBaseURLLiteral,
        path: path,
        method: method,
        headers: headers,
        tags: tags,
        requestBodyExample: requestBodyExample,
        responseStructure: responseStructure,
        responseExample: responseExample
    )
}

func extractTypeName(from expr: ExprSyntax) -> String? {
    if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
        // [Post].self → "[Post]"
        return memberAccess.base?.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return nil
}

func extractStringLiteral(from expr: ExprSyntax) -> String? {
    if let stringLiteral = expr.as(StringLiteralExprSyntax.self) {
        // Multi-line string literal의 모든 세그먼트를 결합
        var result = ""
        for segment in stringLiteral.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result += stringSegment.content.text
            }
        }
        return result.isEmpty ? nil : result
    }
    return nil
}

func extractExpression(from expr: ExprSyntax) -> String? {
    // 표현식 전체를 문자열로 반환 (APIConfiguration.jsonPlaceholder 등)
    return expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
}

func extractEnumCase(from expr: ExprSyntax) -> String? {
    if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
        return memberAccess.declName.baseName.text
    }
    return nil
}

func extractStringOrEnumCase(from expr: ExprSyntax) -> String? {
    // String 리터럴 시도
    if let stringValue = extractStringLiteral(from: expr) {
        return stringValue
    }
    // Enum case 시도 (.get → "get")
    if let enumValue = extractEnumCase(from: expr) {
        return enumValue
    }
    return nil
}

func extractDictionary(from expr: ExprSyntax) -> [String: String] {
    guard let dictionaryExpr = expr.as(DictionaryExprSyntax.self) else {
        return [:]
    }

    var result: [String: String] = [:]

    for element in dictionaryExpr.content.as(DictionaryElementListSyntax.self) ?? [] {
        guard let keyString = extractStringLiteral(from: element.key),
              let valueString = extractStringLiteral(from: element.value)
        else {
            continue
        }
        result[keyString] = valueString
    }

    return result
}

func extractArray(from expr: ExprSyntax) -> [String] {
    guard let arrayExpr = expr.as(ArrayExprSyntax.self) else {
        return []
    }

    var result: [String] = []

    for element in arrayExpr.elements {
        if let stringValue = extractStringLiteral(from: element.expression) {
            result.append(stringValue)
        }
    }

    return result
}

func generateResponseStructure(from responseType: String) -> String? {
    // 배열 타입인 경우 [Type] → Type으로 변환
    let cleanedType = responseType
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "[", with: "")
        .replacingOccurrences(of: "]", with: "")

    // 간단한 타입 매핑 (실제 타입 정의를 코드 문자열로 표현)
    let typeStructures: [String: String] = [
        "Post": """
        struct Post {
            let userId: Int
            let id: Int
            let title: String
            let body: String
        }
        """,
        "User": """
        struct User {
            let id: Int
            let name: String
            let username: String
            let email: String
            let address: Address?
            let phone: String?
            let website: String?
            let company: Company?
        }
        """,
        "Comment": """
        struct Comment {
            let postId: Int
            let id: Int
            let name: String
            let email: String
            let body: String
        }
        """,
        "Album": """
        struct Album {
            let userId: Int
            let id: Int
            let title: String
        }
        """,
        "Photo": """
        struct Photo {
            let albumId: Int
            let id: Int
            let title: String
            let url: String
            let thumbnailUrl: String
        }
        """,
    ]

    return typeStructures[cleanedType]
}

// MARK: - Request Body Field Parsing

struct ParsedRequestBodyField {
    let name: String
    let type: String
    let isRequired: Bool
    let exampleValue: String?
}

/// requestBodyExample JSON 문자열에서 필드 정보를 파싱합니다
func parseRequestBodyFields(from jsonString: String) -> [ParsedRequestBodyField] {
    guard let data = jsonString.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        return []
    }

    return flattenFields(from: jsonObject, prefix: "").sorted { $0.name < $1.name }
}

/// 중첩된 객체를 평면화하여 필드 목록 생성
private func flattenFields(from dictionary: [String: Any], prefix: String) -> [ParsedRequestBodyField] {
    var fields: [ParsedRequestBodyField] = []

    for (key, value) in dictionary {
        let fieldName = prefix.isEmpty ? key : "\(prefix).\(key)"

        switch value {
        case let dict as [String: Any]:
            // 중첩된 객체는 재귀적으로 평면화
            fields.append(contentsOf: flattenFields(from: dict, prefix: fieldName))
        case let array as [Any]:
            // 배열의 경우
            if let firstElement = array.first as? [String: Any] {
                // 배열의 첫 번째 요소가 객체면 그 구조를 사용
                let arrayFields = flattenFields(from: firstElement, prefix: "\(fieldName)[0]")
                fields.append(contentsOf: arrayFields)
            } else {
                // 기본 타입 배열
                let fieldType = detectArrayElementType(from: array)
                let exampleValue = formatArrayExample(from: array)
                fields.append(ParsedRequestBodyField(
                    name: fieldName,
                    type: "[\(fieldType)]",
                    isRequired: true,
                    exampleValue: exampleValue
                ))
            }
        default:
            // 기본 타입
            let fieldType = detectFieldType(from: value)
            let exampleValue = stringValue(from: value)
            fields.append(ParsedRequestBodyField(
                name: fieldName,
                type: fieldType,
                isRequired: true,
                exampleValue: exampleValue
            ))
        }
    }

    return fields
}

/// 배열 요소의 타입 감지
private func detectArrayElementType(from array: [Any]) -> String {
    guard let first = array.first else { return "Any" }
    return detectFieldType(from: first)
}

/// 배열 예시값 포맷팅
private func formatArrayExample(from array: [Any]) -> String {
    if array.isEmpty { return "[]" }
    if array.count <= 2 {
        let values = array.map { stringValue(from: $0) }
        return "[\(values.joined(separator: ", "))]"
    }
    return "[\(array.count) items]"
}

/// 값의 타입 감지
private func detectFieldType(from value: Any) -> String {
    switch value {
    case is String:
        return "String"
    case is Int:
        return "Int"
    case is Double, is Float:
        return "Double"
    case is Bool:
        return "Bool"
    case is [Any]:
        return "Array"
    case is [String: Any]:
        return "Object"
    default:
        return "Unknown"
    }
}

/// 값을 문자열로 변환
private func stringValue(from value: Any) -> String {
    switch value {
    case let str as String:
        return str
    case let num as NSNumber:
        return num.stringValue
    case let array as [Any]:
        return "[\(array.count) items]"
    case let dict as [String: Any]:
        return "{\(dict.count) fields}"
    default:
        return "\(value)"
    }
}

// MARK: - Plugin Registration

@main
struct AsyncNetworkMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIRequestMacroImpl.self,
    ]
}
