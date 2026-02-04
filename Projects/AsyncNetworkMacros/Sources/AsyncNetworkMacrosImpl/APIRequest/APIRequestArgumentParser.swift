import SwiftSyntax

// MARK: - MethodParseResult

/// Method 파싱 결과를 나타내는 열거형
///
/// Phase 4: parseMethod와 parseDynamicMethod 로직 통합
enum MethodParseResult {
    /// 정적 메서드 (enum case)
    /// - Parameter value: HTTP 메서드 이름 ("get", "post" 등)
    case `static`(String)

    /// 동적 메서드 (프로퍼티 참조)
    /// - Parameter propertyName: 참조할 프로퍼티 이름 (예: "httpMethod")
    case dynamic(String)

    /// 메서드 이름 반환 (정적/동적 공통)
    var methodName: String {
        switch self {
        case let .static(name):
            return name
        case let .dynamic(propertyName):
            return propertyName
        }
    }

    /// 동적 메서드 여부
    var isDynamic: Bool {
        if case .dynamic = self {
            return true
        }
        return false
    }

    /// 동적 메서드의 프로퍼티 이름 (동적이 아니면 nil)
    var dynamicPropertyName: String? {
        if case let .dynamic(propertyName) = self {
            return propertyName
        }
        return nil
    }
}

public struct APIRequestArgumentParser {
    public let context: MacroContext
    public let expressionParser: ExpressionParser
    public let pathParser: PathParser

    public init(
        context: MacroContext,
        expressionParser: ExpressionParser,
        pathParser: PathParser
    ) {
        self.context = context
        self.expressionParser = expressionParser
        self.pathParser = pathParser
    }

    public func parse() throws -> MacroArguments {
        guard let arguments = context.arguments else {
            throw MacroError.missingArguments
        }

        let responseType = try parseResponseType(from: arguments)
        let baseURL = try parseBaseURL(from: arguments)
        let path = try parsePath(from: arguments)

        // Phase 4: 통합된 메서드 파싱
        let methodResult = try parseMethod(from: arguments)

        // Phase 3: Optional arguments
        let validationLevel = parseValidationLevel(from: arguments)

        let optionalPathParameters = pathParser.extractOptionalParameters(from: path)

        return MacroArguments(
            responseType: responseType,
            baseURL: baseURL.value,
            isBaseURLLiteral: baseURL.isLiteral,
            path: path,
            method: methodResult.methodName,
            validationLevel: validationLevel,
            isDynamicMethod: methodResult.isDynamic,
            dynamicMethodProperty: methodResult.dynamicPropertyName,
            optionalPathParameters: optionalPathParameters
        )
    }

    private func parseResponseType(from arguments: LabeledExprListSyntax) throws -> String {
        guard let expr = findArgument(labeled: "response", in: arguments) else {
            throw MacroError.missingRequiredArgument("response", expectedType: "Type.self")
        }

        do {
            return try expressionParser.extractTypeName(from: expr)
        } catch {
            throw MacroError.invalidArgument(
                "response",
                reason: "타입 추출 실패 - \(error.localizedDescription)",
                suggestion: "MyType.self 형식으로 작성하세요"
            )
        }
    }

    private func parseBaseURL(from arguments: LabeledExprListSyntax) throws -> (value: String, isLiteral: Bool) {
        guard let expr = findArgument(labeled: "baseURL", in: arguments) else {
            throw MacroError.missingRequiredArgument("baseURL", expectedType: "String")
        }

        if let literal = try? expressionParser.extractString(from: expr) {
            return (literal, true)
        }

        let expression = expressionParser.extractStringOrExpression(from: expr)
        return (expression, false)
    }

    private func parsePath(from arguments: LabeledExprListSyntax) throws -> String {
        guard let expr = findArgument(labeled: "path", in: arguments) else {
            throw MacroError.missingRequiredArgument("path", expectedType: "String")
        }

        do {
            return try expressionParser.extractString(from: expr)
        } catch {
            throw MacroError.invalidArgument(
                "path",
                reason: "문자열 리터럴이 아닙니다",
                suggestion: "\"/users\" 형식으로 작성하세요"
            )
        }
    }

    /// Phase 4: 메서드 파싱 (정적/동적 통합)
    ///
    /// - Parameter arguments: 매크로 인자 리스트
    /// - Returns: 파싱 결과 (정적 또는 동적)
    /// - Throws: 메서드 인자가 없거나 유효하지 않은 경우
    private func parseMethod(from arguments: LabeledExprListSyntax) throws -> MethodParseResult {
        guard let expr = findArgument(labeled: "method", in: arguments) else {
            throw MacroError.missingRequiredArgument("method", expectedType: "HTTPMethod")
        }

        // 1. 동적 메서드: 변수명 참조 (예: httpMethod)
        if let identifierExpr = expr.as(DeclReferenceExprSyntax.self) {
            return .dynamic(identifierExpr.baseName.text)
        }

        // 2. 정적 메서드: enum case (예: .get, .post)
        if expr.is(MemberAccessExprSyntax.self) {
            do {
                let caseName = try expressionParser.extractEnumCase(from: expr)
                return .static(caseName)
            } catch {
                throw MacroError.invalidArgument(
                    "method",
                    reason: error.localizedDescription,
                    suggestion: "HTTPMethod 열거형 케이스(.get, .post 등)를 사용하세요"
                )
            }
        }

        // 3. 그 외의 경우 에러
        throw MacroError.invalidArgument(
            "method",
            reason: "지원하지 않는 형식입니다",
            suggestion: "HTTPMethod 열거형 케이스(.get, .post 등) 또는 AsyncNetwork.HTTPMethod 타입 변수를 사용하세요"
        )
    }

    // MARK: - Phase 3: Optional Arguments

    /// ValidationLevel 파싱 (기본값: .strict)
    private func parseValidationLevel(from arguments: LabeledExprListSyntax) -> ValidationLevel {
        guard let expr = findArgument(labeled: "validationLevel", in: arguments) else {
            return .default
        }

        // .strict, .moderate, .lenient 형태 파싱
        if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
            let name = memberAccess.declName.baseName.text
            return ValidationLevel(rawValue: name) ?? .default
        }

        return .default
    }

    private func findArgument(
        labeled label: String,
        in arguments: LabeledExprListSyntax
    ) -> ExprSyntax? {
        for argument in arguments where argument.label?.text == label {
            return argument.expression
        }
        return nil
    }
}
