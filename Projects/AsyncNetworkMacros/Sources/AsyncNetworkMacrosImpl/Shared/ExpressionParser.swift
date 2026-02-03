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
}

// MARK: - ExpressionParserError

public enum ExpressionParserError: Error, CustomStringConvertible {
    case invalidTypeName(String)
    case expectedStringLiteral(String)
    case emptyString
    case expectedEnumCase(String)

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
        }
    }
}
