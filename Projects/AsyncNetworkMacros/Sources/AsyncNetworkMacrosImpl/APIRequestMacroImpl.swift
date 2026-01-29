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
public enum APIRequestMacroError: CustomStringConvertible, Error, DiagnosticMessage {
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
/// - var task: HTTPTask
///
/// 사용 예시:
public struct APIRequestMacroImpl: MemberMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let facade = APIRequestMacroFacade()
        return try facade.expand(
            node: node,
            declaration: declaration,
            context: context
        )
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

    // MARK: - Deprecated Methods (Moved to Facade and Generators)
    // 
    // ⚠️ The following methods were moved to dedicated classes for better separation of concerns:
    // - Validation → MacroContext, APIRequestArgumentParser
    // - Property Generation → PropertyGenerator, PathGenerator
    // - Metadata Generation → MetadataGenerator
    // - Suggestions → PropertyWrapperValidator
    //
    // These methods are kept here for reference but are no longer used.

    // ⚠️ DEPRECATED: Moved to PropertyWrapperValidator
    // These validation and suggestion methods are no longer used.
    // See: Projects/AsyncNetworkMacros/Sources/AsyncNetworkMacrosImpl/Domain/Validators/PropertyWrapperValidator.swift

    // ⚠️ DEPRECATED: Moved to @APITestable macro
    // Mock scenario and response generation moved to APITestableMacroImpl.swift

    // ⚠️ DEPRECATED: Moved to MetadataGenerator
    // Metadata generation is now handled by Domain/Generators/MetadataGenerator.swift
}

// MARK: - Plugin Registration

@main
struct AsyncNetworkMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIRequestMacroImpl.self,
        APIDocumentMacroImpl.self,
        APITestableMacroImpl.self,
        ResponseDocumentMacroImpl.self,
        ResponseTestableMacroImpl.self
    ]
}
