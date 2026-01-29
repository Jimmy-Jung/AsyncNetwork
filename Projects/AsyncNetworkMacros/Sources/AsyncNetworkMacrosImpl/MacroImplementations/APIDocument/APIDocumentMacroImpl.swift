import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - APIDocumentMacroError

/// @APIDocument 매크로 에러 타입
///
/// @APIDocument 매크로 확장 중 발생할 수 있는 에러를 정의합니다.
/// 모든 에러는 컴파일 타임에 사용자에게 명확한 진단 메시지와 함께 표시됩니다.
public enum APIDocumentMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    /// struct가 아닌 타입에 매크로가 적용된 경우
    ///
    /// @APIDocument는 struct 타입에만 적용할 수 있습니다.
    /// class, enum, actor에는 적용할 수 없습니다.
    ///
    /// ## 발생 예시
    /// ```swift
    /// @APIDocument(title: "Test")
    /// class MyRequest { }  // ❌ 에러 발생
    /// ```
    case onlyApplicableToStruct

    /// @APIRequest 매크로가 선언되지 않은 경우
    ///
    /// @APIDocument는 반드시 @APIRequest와 함께 사용해야 합니다.
    /// @APIRequest가 먼저 선언되지 않으면 이 에러가 발생합니다.
    ///
    /// ## 발생 예시
    /// ```swift
    /// @APIDocument(title: "Test")
    /// struct MyRequest { }  // ❌ @APIRequest가 없음
    /// ```
    ///
    /// ## 해결 방법
    /// ```swift
    /// @APIRequest(...)  // ✅ 먼저 선언
    /// @APIDocument(...)
    /// struct MyRequest { }
    /// ```
    case missingAPIRequest

    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@APIDocument can only be applied to a struct"
        case .missingAPIRequest:
            return """
            @APIDocument requires @APIRequest to be declared first.

            Usage:
            @APIRequest(...)
            @APIDocument(...)
            struct YourRequest { }
            """
        }
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "APIDocumentMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - APIDocumentMacroImpl

/// @APIDocument 매크로 구현체
///
/// @APIRequest와 함께 사용하여 API 엔드포인트에 대한 풍부한 문서화 메타데이터를 생성합니다.
///
/// ## 매크로 역할
///
/// 1. **MemberMacro**: `metadata` static 프로퍼티 생성
///    - `EndpointMetadata` 타입의 메타데이터 제공
///    - title, description, tags, parameters, headers 정보 포함
///
/// 2. **ExtensionMacro**: `DocumentableAPIRequest` 프로토콜 채택
///    - API Playground 및 문서 생성 도구에서 타입 식별 가능
///
/// ## 생성 과정
///
/// 1. 구조체 타입 검증 (class, enum 불가)
/// 2. @APIRequest 매크로 존재 확인
/// 3. @APIRequest 인자 파싱 (baseURL, path, method 등)
/// 4. @APIDocument 인자 파싱 (title, description, tags)
/// 5. PropertyWrapper 스캔 (@HeaderField, @PathParameter, @QueryParameter)
/// 6. 모든 정보를 조합하여 `metadata` 코드 생성
///
/// ## 특수문자 처리
///
/// 모든 문자열 값은 `escapeForStringLiteral()`을 통해 안전하게 이스케이프됩니다:
/// - `\` → `\\`
/// - `"` → `\"`
/// - `\n` → `\\n`
/// - `\r` → `\\r`
/// - `\t` → `\\t`
///
/// ## 생성 예시
///
/// **입력:**
/// ```swift
/// @APIRequest(
///     response: PostDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/posts",
///     method: .get
/// )
/// @APIDocument(
///     title: "Get posts",
///     description: "포스트 목록 조회",
///     tags: ["Posts", "Read"]
/// )
/// struct GetPostsRequest {
///     @QueryParameter var page: Int?
/// }
/// ```
///
/// **출력 (생성된 코드):**
/// ```swift
/// struct GetPostsRequest {
///     @QueryParameter var page: Int?
///
///     // ... @APIRequest가 생성한 코드 ...
///
///     /// 엔드포인트 메타데이터
///     public static var metadata: EndpointMetadata {
///         EndpointMetadata(
///             id: "GetPostsRequest",
///             title: "Get posts",
///             description: "포스트 목록 조회",
///             method: "GET",
///             path: "/posts",
///             baseURLString: "https://api.example.com",
///             headers: [:],
///             tags: ["Posts", "Read"],
///             parameters: ["page"],
///             responseTypeName: "PostDTO"
///         )
///     }
/// }
///
/// extension GetPostsRequest: DocumentableAPIRequest {}
/// ```
public struct APIDocumentMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    /// MemberMacro 구현: `metadata` static 프로퍼티 생성
    ///
    /// @APIDocument 매크로가 적용된 struct에 `EndpointMetadata` 타입의
    /// `metadata` static 프로퍼티를 추가합니다.
    ///
    /// - Parameters:
    ///   - node: @APIDocument 어트리뷰트 구문
    ///   - declaration: 매크로가 적용된 선언 (struct)
    ///   - protocols: 채택할 프로토콜 목록 (사용 안 함)
    ///   - context: 매크로 확장 컨텍스트 (에러 진단용)
    ///
    /// - Returns: 생성된 `metadata` 프로퍼티 선언 배열
    ///
    /// - Throws:
    ///   - `APIDocumentMacroError.onlyApplicableToStruct`: struct가 아닌 타입에 적용
    ///   - `APIDocumentMacroError.missingAPIRequest`: @APIRequest가 없음
    ///   - `APIRequestMacroError.missingArguments`: @APIRequest 인자 없음
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
                message: APIDocumentMacroError.missingAPIRequest
            )
            context.diagnose(diagnostic)
            throw APIDocumentMacroError.missingAPIRequest
        }

        // 3. @APIRequest의 인자 파싱
        let apiRequestArgs = try parseAPIRequestArguments(from: apiRequestAttr, context: context)

        // 4. @APIDocument의 인자 파싱
        let documentArgs = try parseAPIDocumentArguments(from: node, context: context)

        // 5. PropertyWrapper 스캔 (headers, parameters)
        let scanner = PropertyWrapperScanner()
        let properties = scanner.scan(from: structDecl)

        // 6. metadata 생성
        let metadata = generateMetadata(
            typeName: structDecl.name.text,
            apiRequestArgs: apiRequestArgs,
            documentArgs: documentArgs,
            properties: properties
        )

        return [metadata]
    }

    // MARK: - ExtensionMacro Implementation

    /// ExtensionMacro 구현: `DocumentableAPIRequest` 프로토콜 채택 extension 생성
    ///
    /// @APIDocument 매크로가 적용된 타입에 `DocumentableAPIRequest` 프로토콜을
    /// 채택하는 extension을 자동으로 추가합니다.
    ///
    /// - Parameters:
    ///   - node: @APIDocument 어트리뷰트 구문 (사용 안 함)
    ///   - declaration: 매크로가 적용된 선언 (사용 안 함)
    ///   - type: extension을 생성할 타입
    ///   - protocols: 채택할 프로토콜 목록 (사용 안 함)
    ///   - context: 매크로 확장 컨텍스트 (사용 안 함)
    ///
    /// - Returns: `DocumentableAPIRequest` 프로토콜을 채택하는 extension 배열
    ///
    /// ## 생성 예시
    /// ```swift
    /// extension GetPostsRequest: DocumentableAPIRequest {}
    /// ```
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // DocumentableAPIRequest 프로토콜 채택
        let ext: DeclSyntax =
            """
            extension \(type.trimmed): DocumentableAPIRequest {}
            """

        guard let extensionDeclSyntax = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Helper Methods

    /// 문자열 리터럴을 위한 escape 처리
    ///
    /// Swift 문자열 리터럴 내에서 안전하게 사용할 수 있도록
    /// 특수문자를 이스케이프합니다.
    ///
    /// ## 처리되는 특수문자
    /// - `\` → `\\` (백슬래시)
    /// - `"` → `\"` (따옴표)
    /// - `\n` → `\\n` (개행)
    /// - `\r` → `\\r` (캐리지 리턴)
    /// - `\t` → `\\t` (탭)
    ///
    /// ## 사용 예시
    /// ```swift
    /// let input = "Hello \"World\"\nNew line"
    /// let escaped = escapeForStringLiteral(input)
    /// // 결과: "Hello \\\"World\\\"\\nNew line"
    /// ```
    ///
    /// ## 필요성
    /// 사용자가 입력한 문자열을 Swift 코드로 생성할 때,
    /// 특수문자가 그대로 포함되면 컴파일 오류가 발생합니다.
    /// 이 함수는 모든 문자열을 안전하게 변환합니다.
    ///
    /// - Parameter string: 이스케이프할 원본 문자열
    /// - Returns: 이스케이프된 문자열
    private static func escapeForStringLiteral(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    /// 구조체 선언을 검증합니다.
    ///
    /// @APIDocument 매크로가 struct 타입에만 적용되었는지 확인합니다.
    /// struct가 아닌 경우 컴파일 에러와 함께 진단 메시지를 표시합니다.
    ///
    /// - Parameters:
    ///   - declaration: 검증할 선언 (DeclGroupSyntax)
    ///   - node: 에러 위치를 표시할 어트리뷰트 노드
    ///   - context: 진단 메시지를 추가할 컨텍스트
    ///
    /// - Returns: 검증된 StructDeclSyntax
    ///
    /// - Throws: `APIDocumentMacroError.onlyApplicableToStruct` - struct가 아닌 경우
    private static func validateStructDeclaration(
        _ declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> StructDeclSyntax {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: APIDocumentMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            throw APIDocumentMacroError.onlyApplicableToStruct
        }
        return structDecl
    }

    /// declaration에서 @APIRequest 어트리뷰트를 찾습니다.
    ///
    /// 동일한 struct에 적용된 모든 어트리뷰트를 순회하면서
    /// @APIRequest 매크로를 찾습니다.
    ///
    /// - Parameter declaration: 어트리뷰트를 검색할 선언
    ///
    /// - Returns: @APIRequest 어트리뷰트 (없으면 nil)
    ///
    /// ## 검색 로직
    /// 1. declaration.attributes 배열 순회
    /// 2. 각 attribute를 AttributeSyntax로 캐스팅
    /// 3. attributeName이 "APIRequest"인지 확인
    /// 4. 찾으면 즉시 반환, 없으면 nil 반환
    private static func findAPIRequestAttribute(
        from declaration: some DeclGroupSyntax
    ) -> AttributeSyntax? {
        for attribute in declaration.attributes {
            if let customAttribute = attribute.as(AttributeSyntax.self),
               customAttribute.attributeName.trimmedDescription == "APIRequest" {
                return customAttribute
            }
        }
        return nil
    }

    /// @APIRequest의 인자를 파싱합니다.
    ///
    /// @APIRequest 매크로의 인자들(response, baseURL, path, method 등)을
    /// 파싱하여 `MacroArguments` 구조체로 변환합니다.
    ///
    /// - Parameters:
    ///   - attribute: @APIRequest 어트리뷰트 구문
    ///   - context: 에러 진단을 위한 컨텍스트
    ///
    /// - Returns: 파싱된 매크로 인자
    ///
    /// - Throws:
    ///   - `APIRequestMacroError.missingArguments` - 인자가 없는 경우
    ///   - 기타 파싱 중 발생하는 에러
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

        // 직접 파싱 (APIRequestArgumentParser는 MacroContext 필요)
        let expressionParser = ExpressionParser()
        let pathParser = PathParser()

        var responseType: String?
        var title = ""
        var description = ""
        var baseURL: String?
        var isBaseURLLiteral = false
        var path: String?
        var method: String?
        var tags: [String] = []
        var testScenarios: [String] = []
        var errorExamples: [String: String] = [:]
        var includeRetryTests = true
        var includePerformanceTests = false

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "response":
                responseType = try? expressionParser.extractTypeName(from: expr)
            case "title":
                title = (try? expressionParser.extractString(from: expr)) ?? ""
            case "description":
                description = (try? expressionParser.extractString(from: expr)) ?? ""
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
            case "tags":
                tags = expressionParser.extractStringArray(from: expr)
            case "testScenarios":
                testScenarios = expressionParser.extractEnumCaseArray(from: expr)
            case "errorExamples":
                errorExamples = expressionParser.extractStringDictionary(from: expr)
            case "includeRetryTests":
                includeRetryTests = (try? expressionParser.extractBoolean(from: expr)) ?? true
            case "includePerformanceTests":
                includePerformanceTests = (try? expressionParser.extractBoolean(from: expr)) ?? false
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
            title: title,
            description: description,
            baseURL: baseURL,
            isBaseURLLiteral: isBaseURLLiteral,
            path: path,
            method: method,
            tags: tags,
            optionalPathParameters: optionalPathParameters,
            testScenarios: testScenarios,
            errorExamples: errorExamples,
            includeRetryTests: includeRetryTests,
            includePerformanceTests: includePerformanceTests
        )
    }

    /// @APIDocument의 인자를 파싱합니다.
    ///
    /// @APIDocument 매크로의 인자들(title, description, tags)을
    /// 파싱하여 `DocumentArguments` 구조체로 변환합니다.
    ///
    /// - Parameters:
    ///   - node: @APIDocument 어트리뷰트 구문
    ///   - context: 매크로 확장 컨텍스트 (현재 미사용)
    ///
    /// - Returns: 파싱된 문서화 인자 (인자가 없으면 기본값 반환)
    ///
    /// ## 파싱 로직
    /// 1. 인자가 없으면 모든 필드를 기본값으로 설정
    /// 2. 각 인자 레이블(title, description, tags)에 따라 파싱
    /// 3. title, description은 문자열 리터럴 추출
    /// 4. tags는 문자열 배열로 추출
    ///
    /// ## 기본값
    /// - title: `""`
    /// - description: `""`
    /// - tags: `[]`
    private static func parseAPIDocumentArguments(
        from node: AttributeSyntax,
        context _: some MacroExpansionContext
    ) throws -> DocumentArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // 인자가 없으면 기본값 사용
            return DocumentArguments(title: "", description: "", tags: [])
        }

        let expressionParser = ExpressionParser()
        var title = ""
        var description = ""
        var tags: [String] = []

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "title":
                title = (try? expressionParser.extractString(from: expr)) ?? ""
            case "description":
                description = (try? expressionParser.extractString(from: expr)) ?? ""
            case "tags":
                tags = expressionParser.extractStringArray(from: expr)
            default:
                break
            }
        }

        return DocumentArguments(title: title, description: description, tags: tags)
    }

    /// EndpointMetadata를 생성합니다.
    ///
    /// 모든 파싱된 정보를 조합하여 `EndpointMetadata`를 생성하는 Swift 코드를 반환합니다.
    ///
    /// - Parameters:
    ///   - typeName: Request 타입의 이름 (예: "GetPostsRequest")
    ///   - apiRequestArgs: @APIRequest에서 파싱한 인자들
    ///   - documentArgs: @APIDocument에서 파싱한 인자들
    ///   - properties: PropertyWrapper 스캔 결과
    ///
    /// - Returns: `metadata` static 프로퍼티를 정의하는 DeclSyntax
    ///
    /// ## 생성 과정
    ///
    /// 1. **tags 배열 생성**
    ///    - 각 태그를 escape 처리
    ///    - 쉼표로 구분된 문자열 배열 생성
    ///
    /// 2. **title과 description escape 처리**
    ///    - 특수문자를 안전하게 이스케이프
    ///
    /// 3. **headers 딕셔너리 생성**
    ///    - @HeaderField와 @CustomHeader에서 추출
    ///    - key와 defaultValue를 모두 escape 처리
    ///    - 빈 경우 `[:]` 반환
    ///
    /// 4. **parameters 배열 생성**
    ///    - @PathParameter와 @QueryParameter 이름 추출
    ///    - 각 이름을 escape 처리
    ///    - 빈 경우 `[]` 반환
    ///
    /// 5. **baseURL 처리**
    ///    - 문자열 리터럴인 경우 escape 처리 후 따옴표로 감싸기
    ///    - 표현식인 경우 그대로 사용
    ///
    /// 6. **path, typeName, responseType escape 처리**
    ///    - 모든 문자열 필드를 안전하게 변환
    ///
    /// ## 생성 예시
    ///
    /// **입력:**
    /// ```
    /// typeName: "GetPostsRequest"
    /// apiRequestArgs.method: "get"
    /// documentArgs.title: "Get posts"
    /// documentArgs.tags: ["Posts", "Read"]
    /// ```
    ///
    /// **출력:**
    /// ```swift
    /// /// 엔드포인트 메타데이터
    /// public static var metadata: EndpointMetadata {
    ///     EndpointMetadata(
    ///         id: "GetPostsRequest",
    ///         title: "Get posts",
    ///         description: "",
    ///         method: "GET",
    ///         path: "/posts",
    ///         baseURLString: "https://api.example.com",
    ///         headers: [:],
    ///         tags: ["Posts", "Read"],
    ///         parameters: [],
    ///         responseTypeName: "PostDTO"
    ///     )
    /// }
    /// ```
    private static func generateMetadata(
        typeName: String,
        apiRequestArgs: MacroArguments,
        documentArgs: DocumentArguments,
        properties: [PropertyWrapperInfo]
    ) -> DeclSyntax {
        // tags 배열을 문자열로 변환 (각 요소를 escape 처리)
        let tagsString = documentArgs.tags
            .map { "\"\(escapeForStringLiteral($0))\"" }
            .joined(separator: ", ")

        // title과 description escape 처리
        let escapedTitle = escapeForStringLiteral(documentArgs.title)
        let escapedDescription = escapeForStringLiteral(documentArgs.description)

        // @HeaderField 및 @CustomHeader의 기본값을 headers 딕셔너리로 변환
        var headerEntries: [String] = []
        for prop in properties {
            if prop.wrapperType == "HeaderField" || prop.wrapperType == "CustomHeader",
               let headerKey = prop.headerKey,
               let defaultValue = prop.defaultValue {
                // headerKey와 기본값을 모두 escape 처리
                let escapedKey = escapeForStringLiteral(headerKey)
                let escapedValue = escapeForStringLiteral(defaultValue)
                headerEntries.append("\"\(escapedKey)\": \"\(escapedValue)\"")
            }
        }
        let headersString = headerEntries.isEmpty ? "[:]" : "[\(headerEntries.joined(separator: ", "))]"

        // @PathParameter, @QueryParameter 이름을 parameters 배열로 변환 (escape 처리)
        let parameterNames = properties
            .filter { ["PathParameter", "QueryParameter"].contains($0.wrapperType) }
            .map { "\"\(escapeForStringLiteral($0.name))\"" }
        let parametersString = parameterNames.isEmpty ? "[]" : "[\(parameterNames.joined(separator: ", "))]"

        // baseURL을 문자열 리터럴 또는 표현식으로 처리
        let baseURLString: String
        if apiRequestArgs.isBaseURLLiteral {
            baseURLString = "\"\(escapeForStringLiteral(apiRequestArgs.baseURL))\""
        } else {
            baseURLString = apiRequestArgs.baseURL
        }

        // path, typeName, responseType escape 처리
        let escapedPath = escapeForStringLiteral(apiRequestArgs.path)
        let escapedTypeName = escapeForStringLiteral(typeName)
        let escapedResponseType = escapeForStringLiteral(apiRequestArgs.responseType)

        return """
        /// 엔드포인트 메타데이터
        public static var metadata: EndpointMetadata {
            EndpointMetadata(
                id: "\(raw: escapedTypeName)",
                title: "\(raw: escapedTitle)",
                description: "\(raw: escapedDescription)",
                method: "\(raw: apiRequestArgs.method.uppercased())",
                path: "\(raw: escapedPath)",
                baseURLString: \(raw: baseURLString),
                headers: \(raw: headersString),
                tags: [\(raw: tagsString)],
                parameters: \(raw: parametersString),
                responseTypeName: "\(raw: escapedResponseType)"
            )
        }
        """
    }
}
