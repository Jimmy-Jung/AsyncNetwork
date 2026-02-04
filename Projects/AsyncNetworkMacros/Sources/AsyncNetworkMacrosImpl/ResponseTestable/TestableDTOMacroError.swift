import SwiftDiagnostics

public enum TestableDTOMacroError: Error, DiagnosticMessage {
    case notAStructOrEnum

    public var message: String {
        switch self {
        case .notAStructOrEnum:
            return "@ResponseTestable은 struct 또는 enum에만 적용할 수 있습니다"
        }
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "TestableDTOMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}
