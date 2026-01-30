import SwiftSyntax

public struct ExpressionParser {
    public init() {}

    // MARK: - Type Name Extraction

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

    public func extractStringOrExpression(from expr: ExprSyntax) -> String {
        if let literal = try? extractString(from: expr) {
            return literal
        }
        return expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Enum Case Extraction

    public func extractEnumCase(from expr: ExprSyntax) throws -> String {
        guard let memberAccess = expr.as(MemberAccessExprSyntax.self) else {
            throw ExpressionParserError.expectedEnumCase(expr.description)
        }
        return memberAccess.declName.baseName.text
    }

    // MARK: - Array Extraction

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

    public func extractStringDictionary(from expr: ExprSyntax) -> [String: String] {
        guard let dictExpr = expr.as(DictionaryExprSyntax.self),
              let elements = dictExpr.content.as(DictionaryElementListSyntax.self)
        else {
            return [:]
        }

        var result: [String: String] = [:]

        for element in elements {
            guard let keyString = try? extractString(from: element.key) else {
                continue
            }

            guard let valueString = try? extractString(from: element.value) else {
                continue
            }

            result[keyString] = valueString
        }

        return result
    }

    // MARK: - Boolean Extraction

    public func extractBoolean(from expr: ExprSyntax) throws -> Bool {
        guard let boolLiteral = expr.as(BooleanLiteralExprSyntax.self) else {
            throw ExpressionParserError.expectedBoolean(expr.description)
        }
        return boolLiteral.literal.text == "true"
    }
}

// MARK: - ExpressionParserError

public enum ExpressionParserError: Error, CustomStringConvertible {
    case invalidTypeName(String)
    case expectedStringLiteral(String)
    case emptyString
    case expectedEnumCase(String)
    case expectedBoolean(String)

    public var description: String {
        switch self {
        case let .invalidTypeName(expr):
            return "유효하지 않은 타입 이름: \(expr)"
        case let .expectedStringLiteral(expr):
            return "문자열 리터럴이 필요하지만 다른 값이 제공되었습니다: \(expr)"
        case .emptyString:
            return "문자열 리터럴이 비어있습니다"
        case let .expectedEnumCase(expr):
            return "열거형 케이스가 필요하지만 다른 값이 제공되었습니다: \(expr)"
        case let .expectedBoolean(expr):
            return "불린 값이 필요하지만 다른 값이 제공되었습니다: \(expr)"
        }
    }
}
