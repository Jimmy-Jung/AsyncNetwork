//
//  APIDocumentMacroImpl.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/12.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - APIDocumentMacroError

/// APIDocument 매크로 에러 타입
public enum APIDocumentMacroError: CustomStringConvertible, Error, DiagnosticMessage {
    case onlyApplicableToStruct
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

/// @APIDocument 매크로 구현
///
/// @APIRequest와 함께 사용하여 API 문서화 메타데이터를 생성합니다.
public struct APIDocumentMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

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
        let properties = scanPropertyWrappers(from: structDecl)

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

    /// 구조체 선언을 검증합니다.
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
    private static func findAPIRequestAttribute(
        from declaration: some DeclGroupSyntax
    ) -> AttributeSyntax? {
        for attribute in declaration.attributes {
            if let customAttribute = attribute.as(AttributeSyntax.self),
               customAttribute.attributeName.trimmedDescription == "APIRequest"
            {
                return customAttribute
            }
        }
        return nil
    }

    /// @APIRequest의 인자를 파싱합니다.
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

        return try parseArguments(arguments)
    }

    /// @APIDocument의 인자를 파싱합니다.
    private static func parseAPIDocumentArguments(
        from node: AttributeSyntax,
        context _: some MacroExpansionContext
    ) throws -> DocumentArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // 인자가 없으면 기본값 사용
            return DocumentArguments(title: "", description: "", tags: [])
        }

        var title = ""
        var description = ""
        var tags: [String] = []

        for argument in arguments {
            let label = argument.label?.text ?? ""
            let expr = argument.expression

            switch label {
            case "title":
                title = extractStringLiteral(from: expr) ?? ""
            case "description":
                description = extractStringLiteral(from: expr) ?? ""
            case "tags":
                tags = extractArray(from: expr)
            default:
                break
            }
        }

        return DocumentArguments(title: title, description: description, tags: tags)
    }

    /// EndpointMetadata를 생성합니다.
    private static func generateMetadata(
        typeName: String,
        apiRequestArgs: MacroArguments,
        documentArgs: DocumentArguments,
        properties: [PropertyWrapperInfo]
    ) -> DeclSyntax {
        // tags 배열을 문자열로 변환
        let tagsString = documentArgs.tags.map { "\"\($0)\"" }.joined(separator: ", ")

        // description escape 처리
        let escapedDescription = documentArgs.description
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let escapedTitle = documentArgs.title
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // @HeaderField 및 @CustomHeader의 기본값을 headers 딕셔너리로 변환
        var headerEntries: [String] = []
        for prop in properties {
            if prop.wrapperType == "HeaderField" || prop.wrapperType == "CustomHeader",
               let headerKey = prop.headerKey,
               let defaultValue = prop.defaultValue
            {
                // 기본값을 escape 처리
                let escapedValue = defaultValue
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                headerEntries.append("\"\(headerKey)\": \"\(escapedValue)\"")
            }
        }
        let headersString = headerEntries.isEmpty ? "[:]" : "[\(headerEntries.joined(separator: ", "))]"

        // @PathParameter, @QueryParameter 이름을 parameters 배열로 변환
        let parameterNames = properties
            .filter { ["PathParameter", "QueryParameter"].contains($0.wrapperType) }
            .map { "\"\($0.name)\"" }
        let parametersString = parameterNames.isEmpty ? "[]" : "[\(parameterNames.joined(separator: ", "))]"

        // baseURL을 문자열 리터럴 또는 표현식으로 처리
        let baseURLString: String
        if apiRequestArgs.isBaseURLLiteral {
            baseURLString = "\"\(apiRequestArgs.baseURL)\""
        } else {
            baseURLString = apiRequestArgs.baseURL
        }

        return """
        /// 엔드포인트 메타데이터
        public static var metadata: EndpointMetadata {
            EndpointMetadata(
                id: "\(raw: typeName)",
                title: "\(raw: escapedTitle)",
                description: "\(raw: escapedDescription)",
                method: "\(raw: apiRequestArgs.method)",
                path: "\(raw: apiRequestArgs.path)",
                baseURLString: \(raw: baseURLString),
                headers: \(raw: headersString),
                tags: [\(raw: tagsString)],
                parameters: \(raw: parametersString),
                responseTypeName: "\(raw: apiRequestArgs.responseType)"
            )
        }
        """
    }
}

// MARK: - Supporting Types

struct DocumentArguments {
    let title: String
    let description: String
    let tags: [String]
}
