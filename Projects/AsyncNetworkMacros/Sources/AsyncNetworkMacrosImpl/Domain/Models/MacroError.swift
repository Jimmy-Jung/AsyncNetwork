import SwiftDiagnostics

public enum MacroError: Error, DiagnosticMessage {
    case onlyApplicableToStruct
    case missingArguments
    case missingRequiredArgument(String)
    case invalidArgument(String)

    public var message: String {
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

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "MacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}
