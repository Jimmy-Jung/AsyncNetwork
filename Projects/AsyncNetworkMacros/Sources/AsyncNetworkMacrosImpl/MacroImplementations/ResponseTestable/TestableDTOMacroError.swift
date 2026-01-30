import SwiftDiagnostics

public enum TestableDTOMacroError: Error, DiagnosticMessage {
    case notAStruct
    case invalidFixtureJSON(String)
    case emptyFixtureJSON
    case jsonValidationFailed(String)

    public var message: String {
        switch self {
        case .notAStruct:
            return "@ResponseTestable can only be applied to a struct"
        case let .invalidFixtureJSON(reason):
            return "Invalid fixtureJSON: \(reason)"
        case .emptyFixtureJSON:
            return "fixtureJSON cannot be empty"
        case let .jsonValidationFailed(details):
            return "fixtureJSON validation failed: \(details). Please check that the JSON structure matches the struct definition and all nested types have valid fixture data."
        }
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "TestableDTOMacroError")
    }

    public var severity: DiagnosticSeverity {
        switch self {
        case .jsonValidationFailed:
            return .warning
        default:
            return .error
        }
    }
}
