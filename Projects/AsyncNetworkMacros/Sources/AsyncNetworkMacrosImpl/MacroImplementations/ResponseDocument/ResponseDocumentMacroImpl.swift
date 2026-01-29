import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - ResponseDocumentMacroError

/// ResponseDocument 매크로 에러 타입
public enum ResponseDocumentMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    case onlyApplicableToStruct
    case missingFixtureJSON
    case emptyFixtureJSON
    case invalidJSON(String)

    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@ResponseDocument can only be applied to a struct"
        case .missingFixtureJSON:
            return "@ResponseDocument requires 'fixtureJSON' parameter"
        case .emptyFixtureJSON:
            return "fixtureJSON parameter cannot be empty"
        case let .invalidJSON(reason):
            return "Invalid JSON in fixtureJSON parameter: \(reason)"
        }
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "ResponseDocumentMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - ResponseDocumentMacroImpl

/// @ResponseDocument 매크로 구현
///
/// OpenAPI 문서화를 위한 JSON 샘플을 생성합니다.
public struct ResponseDocumentMacroImpl: MemberMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. 구조체 검증
        _ = try validateStructDeclaration(declaration, node: node, context: context)

        // 2. fixtureJSON 파라미터 추출
        guard let fixtureJSON = extractFixtureJSON(from: node, context: context) else {
            let diagnostic = Diagnostic(
                node: node,
                message: ResponseDocumentMacroError.missingFixtureJSON
            )
            context.diagnose(diagnostic)
            throw ResponseDocumentMacroError.missingFixtureJSON
        }

        // 3. 빈 문자열 검증
        guard !fixtureJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let diagnostic = Diagnostic(
                node: node,
                message: ResponseDocumentMacroError.emptyFixtureJSON
            )
            context.diagnose(diagnostic)
            throw ResponseDocumentMacroError.emptyFixtureJSON
        }

        // 4. JSON 유효성 검증
        try validateJSON(fixtureJSON, node: node, context: context)

        // 5. jsonSample 프로퍼티 생성
        return [generateJSONSampleProperty(json: fixtureJSON)]
    }

    // MARK: - Helper Methods

    /// 구조체 선언을 검증합니다.
    private static func validateStructDeclaration(
        _ declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws -> StructDeclSyntax {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: ResponseDocumentMacroError.onlyApplicableToStruct
            )
            context.diagnose(diagnostic)
            throw ResponseDocumentMacroError.onlyApplicableToStruct
        }
        return structDecl
    }

    /// fixtureJSON 파라미터를 추출합니다.
    private static func extractFixtureJSON(
        from node: AttributeSyntax,
        context _: some MacroExpansionContext
    ) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        let expressionParser = ExpressionParser()
        for argument in arguments {
            let label = argument.label?.text ?? ""
            if label == "fixtureJSON" {
                return try? expressionParser.extractString(from: argument.expression)
            }
        }

        return nil
    }

    /// JSON 유효성을 검증합니다.
    private static func validateJSON(
        _ json: String,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) throws {
        guard let data = json.data(using: .utf8) else {
            let diagnostic = Diagnostic(
                node: node,
                message: ResponseDocumentMacroError.invalidJSON("Cannot convert to UTF-8 data")
            )
            context.diagnose(diagnostic)
            throw ResponseDocumentMacroError.invalidJSON("Cannot convert to UTF-8 data")
        }

        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            let diagnostic = Diagnostic(
                node: node,
                message: ResponseDocumentMacroError.invalidJSON(error.localizedDescription)
            )
            context.diagnose(diagnostic)
            throw ResponseDocumentMacroError.invalidJSON(error.localizedDescription)
        }
    }

    /// jsonSample 프로퍼티를 생성합니다.
    private static func generateJSONSampleProperty(json: String) -> DeclSyntax {
        // 들여쓰기 추가 (빈 줄 제외)
        // Note: multi-line string literal 내부에서는 escape 처리가 자동으로 이루어지므로
        // 별도의 escape 처리가 필요하지 않습니다.
        let indented = json
            .components(separatedBy: .newlines)
            .map { $0.isEmpty ? $0 : "    " + $0 }
            .joined(separator: "\n")

        return """
        /// JSON 샘플 문자열
        ///
        /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
        public static var jsonSample: String {
            \"\"\"
        \(raw: indented)
            \"\"\"
        }
        """
    }
}
