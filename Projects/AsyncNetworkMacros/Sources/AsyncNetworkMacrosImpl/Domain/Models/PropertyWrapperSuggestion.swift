//
//  PropertyWrapperSuggestion.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftDiagnostics
import SwiftSyntax

/// Property Wrapper 제안
public struct PropertyWrapperSuggestion: Sendable {
    public let propertyName: String
    public let suggestedWrapper: String
    public let reason: String

    public init(
        propertyName: String,
        suggestedWrapper: String,
        reason: String
    ) {
        self.propertyName = propertyName
        self.suggestedWrapper = suggestedWrapper
        self.reason = reason
    }

    /// Diagnostic으로 변환
    public func toDiagnostic(node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(
            node: node,
            message: Message(suggestion: self)
        )
    }
}

// MARK: - DiagnosticMessage

extension PropertyWrapperSuggestion {
    struct Message: SwiftDiagnostics.DiagnosticMessage {
        let suggestion: PropertyWrapperSuggestion

        var message: String {
            "Consider using '\(suggestion.suggestedWrapper)' for '\(suggestion.propertyName)': \(suggestion.reason)"
        }

        var diagnosticID: MessageID {
            MessageID(domain: "AsyncNetworkMacros", id: "PropertyWrapperSuggestion")
        }

        var severity: DiagnosticSeverity {
            .warning
        }
    }
}
