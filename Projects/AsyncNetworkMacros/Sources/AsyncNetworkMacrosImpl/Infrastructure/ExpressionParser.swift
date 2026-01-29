import SwiftSyntax

/// SwiftSyntax ExprSyntax를 파싱하는 유틸리티
///
/// 이 클래스는 매크로 인자로 전달되는 다양한 표현식을
/// 타입 안전하게 추출합니다.
///
/// ## 지원하는 표현식
/// - String 리터럴: `"hello"`
/// - Enum case: `.get`, `.post`
/// - 타입 이름: `Post.self`, `[Post].self`
/// - 배열: `["tag1", "tag2"]`
/// - 딕셔너리: `["404": "error"]`
/// - 일반 표현식: `APIConfiguration.baseURL`
public struct ExpressionParser {
    public init() {}

    // MARK: - Type Name Extraction

    /// 타입 이름 추출
    ///
    /// - Parameter expr: `Post.self` 또는 `[Post].self`
    /// - Returns: `"Post"` 또는 `"[Post]"`
    /// - Throws: 타입 이름을 추출할 수 없는 경우
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let typeName = try parser.extractTypeName(from: expr)
    /// // typeName == "Post"
    /// ```
    public func extractTypeName(from expr: ExprSyntax) throws -> String {
        guard let memberAccess = expr.as(MemberAccessExprSyntax.self),
              let base = memberAccess.base?.description.trimmingCharacters(in: .whitespacesAndNewlines),
              !base.isEmpty
        else {
            throw ExpressionParserError.invalidTypeName(expr.description)
        }
        return base
    }

    // MARK: - String Extraction

    /// 문자열 리터럴 추출
    ///
    /// - Parameter expr: `"hello"` 또는 `"""multiline"""`
    /// - Returns: 따옴표 안의 문자열
    /// - Throws: 문자열 리터럴이 아닌 경우
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let str = try parser.extractString(from: expr)
    /// // str == "hello"
    /// ```
    public func extractString(from expr: ExprSyntax) throws -> String {
        guard let stringLiteral = expr.as(StringLiteralExprSyntax.self) else {
            throw ExpressionParserError.expectedStringLiteral(expr.description)
        }

        var result = ""
        for segment in stringLiteral.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result += stringSegment.content.text
            }
        }

        guard !result.isEmpty else {
            throw ExpressionParserError.emptyString
        }

        return result
    }

    /// 문자열 또는 표현식 추출
    ///
    /// 문자열 리터럴이면 따옴표 안의 값을 반환하고,
    /// 그렇지 않으면 표현식 전체를 문자열로 반환합니다.
    ///
    /// - Parameter expr: `"https://api.com"` 또는 `APIConfiguration.baseURL`
    /// - Returns: 문자열 또는 표현식
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let value1 = parser.extractStringOrExpression(from: literalExpr)
    /// // value1 == "https://api.com"
    ///
    /// let value2 = parser.extractStringOrExpression(from: expressionExpr)
    /// // value2 == "APIConfiguration.baseURL"
    /// ```
    public func extractStringOrExpression(from expr: ExprSyntax) -> String {
        // 문자열 리터럴이면 따옴표 안의 값 반환
        if let literal = try? extractString(from: expr) {
            return literal
        }
        // 표현식이면 전체 표현식 반환
        return expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Enum Case Extraction

    /// Enum case 추출
    ///
    /// - Parameter expr: `.get`, `.post`, `.put` 등
    /// - Returns: `"get"`, `"post"`, `"put"` 등
    /// - Throws: Enum case가 아닌 경우
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let method = try parser.extractEnumCase(from: expr)
    /// // method == "get"
    /// ```
    public func extractEnumCase(from expr: ExprSyntax) throws -> String {
        guard let memberAccess = expr.as(MemberAccessExprSyntax.self) else {
            throw ExpressionParserError.expectedEnumCase(expr.description)
        }
        return memberAccess.declName.baseName.text
    }

    // MARK: - Array Extraction

    /// 문자열 배열 추출
    ///
    /// - Parameter expr: `["tag1", "tag2", "tag3"]`
    /// - Returns: `["tag1", "tag2", "tag3"]`
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let tags = parser.extractStringArray(from: expr)
    /// // tags == ["tag1", "tag2", "tag3"]
    /// ```
    public func extractStringArray(from expr: ExprSyntax) -> [String] {
        guard let arrayExpr = expr.as(ArrayExprSyntax.self) else {
            return []
        }

        var result: [String] = []
        for element in arrayExpr.elements {
            if let stringValue = try? extractString(from: element.expression) {
                result.append(stringValue)
            }
        }

        return result
    }

    /// Enum case 배열 추출
    ///
    /// - Parameter expr: `[.success, .notFound, .serverError]`
    /// - Returns: `["success", "notFound", "serverError"]`
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let scenarios = parser.extractEnumCaseArray(from: expr)
    /// // scenarios == ["success", "notFound", "serverError"]
    /// ```
    public func extractEnumCaseArray(from expr: ExprSyntax) -> [String] {
        guard let arrayExpr = expr.as(ArrayExprSyntax.self) else {
            return []
        }

        var result: [String] = []
        for element in arrayExpr.elements {
            if let enumCase = try? extractEnumCase(from: element.expression) {
                result.append(enumCase)
            }
        }

        return result
    }

    // MARK: - Dictionary Extraction

    /// 문자열 딕셔너리 추출
    ///
    /// - Parameter expr: `["404": "Not found", "500": "Server error"]`
    /// - Returns: `["404": "Not found", "500": "Server error"]`
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let errors = parser.extractStringDictionary(from: expr)
    /// // errors == ["404": "Not found", "500": "Server error"]
    /// ```
    public func extractStringDictionary(from expr: ExprSyntax) -> [String: String] {
        guard let dictExpr = expr.as(DictionaryExprSyntax.self),
              let elements = dictExpr.content.as(DictionaryElementListSyntax.self)
        else {
            return [:]
        }

        var result: [String: String] = [:]

        for element in elements {
            // Key 추출
            guard let keyString = try? extractString(from: element.key) else {
                continue
            }

            // Value 추출
            guard let valueString = try? extractString(from: element.value) else {
                continue
            }

            result[keyString] = valueString
        }

        return result
    }

    // MARK: - Boolean Extraction

    /// Boolean 값 추출
    ///
    /// - Parameter expr: `true` 또는 `false`
    /// - Returns: Boolean 값
    /// - Throws: Boolean이 아닌 경우
    ///
    /// ## 예시
    /// ```swift
    /// let parser = ExpressionParser()
    /// let flag = try parser.extractBoolean(from: expr)
    /// // flag == true
    /// ```
    public func extractBoolean(from expr: ExprSyntax) throws -> Bool {
        guard let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) else {
            throw ExpressionParserError.expectedBoolean(expr.description)
        }
        return boolLiteral.literal.text == "true"
    }
}

// MARK: - ExpressionParserError

/// ExpressionParser 에러 타입
public enum ExpressionParserError: Error, CustomStringConvertible {
    case invalidTypeName(String)
    case expectedStringLiteral(String)
    case emptyString
    case expectedEnumCase(String)
    case expectedBoolean(String)

    public var description: String {
        switch self {
        case let .invalidTypeName(expr):
            return "Invalid type name: \(expr)"
        case let .expectedStringLiteral(expr):
            return "Expected string literal, got: \(expr)"
        case .emptyString:
            return "String literal is empty"
        case let .expectedEnumCase(expr):
            return "Expected enum case, got: \(expr)"
        case let .expectedBoolean(expr):
            return "Expected boolean, got: \(expr)"
        }
    }
}
