import SwiftDiagnostics

public enum TestableDTOMacroError: Error, DiagnosticMessage {
    case notAStruct
    case invalidFixtureJSON(String)
    case emptyFixtureJSON

    public var message: String {
        switch self {
        case .notAStruct:
            return "@ResponseTestable can only be applied to a struct"
        case let .invalidFixtureJSON(reason):
            return "Invalid fixtureJSON: \(reason)"
        case .emptyFixtureJSON:
            return "fixtureJSON cannot be empty"
        }
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "TestableDTOMacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}
