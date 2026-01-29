import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct MacroContext {
    public let node: AttributeSyntax
    public let declaration: DeclGroupSyntax
    public let expansionContext: any MacroExpansionContext

    public var structDecl: StructDeclSyntax? {
        declaration.as(StructDeclSyntax.self)
    }

    public var arguments: LabeledExprListSyntax? {
        node.arguments?.as(LabeledExprListSyntax.self)
    }

    public var declarationName: String? {
        if let structDecl = structDecl {
            return structDecl.name.text
        }
        return nil
    }

    public func diagnoseError(_ message: some DiagnosticMessage) {
        let diagnostic = Diagnostic(node: node, message: message)
        expansionContext.diagnose(diagnostic)
    }

    public func diagnoseWarning(
        on node: SyntaxProtocol,
        message: some DiagnosticMessage
    ) {
        let diagnostic = Diagnostic(node: node, message: message)
        expansionContext.diagnose(diagnostic)
    }
}
