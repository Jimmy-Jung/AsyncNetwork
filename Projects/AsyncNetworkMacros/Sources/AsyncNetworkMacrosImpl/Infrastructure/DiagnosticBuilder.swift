import SwiftDiagnostics
import SwiftSyntax

public struct DiagnosticBuilder {
    public init() {}

    // MARK: - Error

    public func error(
        on node: some SyntaxProtocol,
        message: String,
        domain: String = "AsyncNetworkMacros",
        id: String = "Error"
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: DiagnosticMessage(
                message: message,
                severity: .error,
                domain: domain,
                id: id
            )
        )
    }

    public func error(
        on node: some SyntaxProtocol,
        diagnosticMessage: some SwiftDiagnostics.DiagnosticMessage
    ) -> Diagnostic {
        Diagnostic(node: node, message: diagnosticMessage)
    }

    // MARK: - Warning

    public func warning(
        on node: some SyntaxProtocol,
        message: String,
        domain: String = "AsyncNetworkMacros",
        id: String = "Warning"
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: DiagnosticMessage(
                message: message,
                severity: .warning,
                domain: domain,
                id: id
            )
        )
    }

    // MARK: - Note

    public func note(
        on node: some SyntaxProtocol,
        message: String,
        domain: String = "AsyncNetworkMacros",
        id: String = "Note"
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: DiagnosticMessage(
                message: message,
                severity: .note,
                domain: domain,
                id: id
            )
        )
    }
}

// MARK: - DiagnosticMessage

extension DiagnosticBuilder {
    /// 간단한 진단 메시지
    struct DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {
        let message: String
        let severity: DiagnosticSeverity
        let domain: String
        let id: String

        var diagnosticID: MessageID {
            MessageID(domain: domain, id: id)
        }
    }
}
