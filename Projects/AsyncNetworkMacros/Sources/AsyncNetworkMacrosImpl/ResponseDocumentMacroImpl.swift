//
//  ResponseDocumentMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/12.
//

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

    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@ResponseDocument can only be applied to a struct"
        case .missingFixtureJSON:
            return "@ResponseDocument requires 'fixtureJSON' parameter"
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

        // 3. jsonSample 프로퍼티 생성
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

        for argument in arguments {
            let label = argument.label?.text ?? ""
            if label == "fixtureJSON" {
                return extractStringLiteral(from: argument.expression)
            }
        }

        return nil
    }

    /// jsonSample 프로퍼티를 생성합니다.
    private static func generateJSONSampleProperty(json: String) -> DeclSyntax {
        // JSON 포맷 유지 (보기 좋게)
        let indented = json
            .components(separatedBy: .newlines)
            .map { "    " + $0 }
            .joined(separator: "\n")

        return """
        /// JSON 샘플 문자열
        public static var jsonSample: String {
            \"\"\"
        \(raw: indented)
            \"\"\"
        }
        """
    }
}
