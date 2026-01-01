//
//  APIRequestMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/01.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

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
        case .missingRequiredArgument(let arg):
            return "@APIRequest missing required argument: \(arg)"
        case .invalidArgument(let arg):
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
        conformingTo protocols: [TypeSyntax],
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
        
        // responseStructure 생성
        let responseStructure = args.responseStructure ?? generateResponseStructure(from: args.responseType)
        
        // responseExample과 requestBodyExample, responseStructure를 raw string으로 변환
        let requestBodyExampleCode: String
        if let example = args.requestBodyExample {
            // 백슬래시와 따옴표를 이스케이프
            let escaped = example
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            requestBodyExampleCode = "\"\(escaped)\""
        } else {
            requestBodyExampleCode = "nil"
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
                    headers: \(raw: args.headers.isEmpty ? "nil" : "[\(args.headers.map { "\"\($0.key)\": \"\($0.value)\"" }.joined(separator: ", "))]"),
                    tags: [\(raw: args.tags.map { "\"\($0)\"" }.joined(separator: ", "))],
                    parameters: \(raw: parametersArray),
                    requestBodyExample: \(raw: requestBodyExampleCode),
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
        conformingTo protocols: [TypeSyntax],
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
                      let identifier = customAttribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
                    continue
                }
                
                let wrapperType = identifier
                guard ["PathParameter", "QueryParameter", "HeaderParameter", "RequestBody"].contains(wrapperType) else {
                    continue
                }
                
                // 프로퍼티 이름 추출
                guard let binding = variableDecl.bindings.first,
                      let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                let propertyName = pattern.identifier.text
                
                // 타입 추출
                let propertyType = extractPropertyType(from: binding) ?? "String"
                
                // 옵셔널 여부 확인
                let isOptional = propertyType.hasSuffix("?")
                
                parameters.append(PropertyWrapperInfo(
                    name: propertyName,
                    type: propertyType,
                    wrapperType: wrapperType,
                    isRequired: !isOptional
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
    
    /// PropertyWrapperInfo 배열을 ParameterInfo 배열 리터럴로 변환합니다.
    private static func generateParametersArray(_ parameters: [PropertyWrapperInfo]) -> String {
        if parameters.isEmpty {
            return "[]"
        }
        
        let parameterStrings = parameters.map { param in
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
    let isBaseURLLiteral: Bool  // baseURL이 문자열 리터럴인지 여부
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
              let valueString = extractStringLiteral(from: element.value) else {
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
        """
    ]
    
    return typeStructures[cleanedType]
}

// MARK: - Plugin Registration

@main
struct AsyncNetworkMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIRequestMacroImpl.self
    ]
}

