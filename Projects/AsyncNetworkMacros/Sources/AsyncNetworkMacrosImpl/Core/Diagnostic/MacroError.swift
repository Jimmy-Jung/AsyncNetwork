import SwiftDiagnostics

public enum MacroError: Error, DiagnosticMessage {
    case onlyApplicableToStruct
    case missingArguments
    case missingRequiredArgument(String)
    case invalidArgument(String)

    public var message: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@APIRequest는 struct에만 적용할 수 있습니다"
        case .missingArguments:
            return "@APIRequest는 인자가 필요합니다"
        case let .missingRequiredArgument(arg):
            return "@APIRequest에 필수 인자가 누락되었습니다: \(arg)"
        case let .invalidArgument(arg):
            return "@APIRequest에 유효하지 않은 인자가 있습니다: \(arg)"
        }
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "MacroError")
    }

    public var severity: DiagnosticSeverity {
        .error
    }
}
