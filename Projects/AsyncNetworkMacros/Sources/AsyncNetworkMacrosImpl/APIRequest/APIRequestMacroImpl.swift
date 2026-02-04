import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - APIRequestMacroImpl

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
        guard declaration.is(StructDeclSyntax.self) else {
            // Fix-it 생성
            let fixIt = FixItBuilder.changeToStruct(from: declaration)
            let diagnostic = MacroError.onlyApplicableToStruct.diagnostic(
                node: node,
                fixIt: fixIt
            )
            context.diagnose(diagnostic)
            return []
        }

        // Phase 4: 모듈 한정자 추가 (타입 충돌 방지)
        // AsyncNetwork.APIRequest로 명시하여 사용자 정의 APIRequest 타입과 충돌 방지
        let ext: DeclSyntax =
            """
            extension \(type.trimmed): AsyncNetwork.APIRequest {}
            """

        guard let extensionDeclSyntax = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }
}
