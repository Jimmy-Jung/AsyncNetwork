import SwiftDiagnostics

public enum TestableDTOMacroError: Error, DiagnosticMessage {
    case notAStructOrEnum
    case invalidFixtureJSON(String)
    case emptyFixtureJSON
    case jsonValidationFailed(String)

    public var message: String {
        switch self {
        case .notAStructOrEnum:
            return "@ResponseTestable은 struct 또는 enum에만 적용할 수 있습니다"
        case let .invalidFixtureJSON(reason):
            return "유효하지 않은 fixtureJSON: \(reason)"
        case .emptyFixtureJSON:
            return "fixtureJSON은 비어있을 수 없습니다"
        case let .jsonValidationFailed(details):
            return """
            fixtureJSON 검증 실패: \(details). \
            JSON 구조가 struct 정의와 일치하는지, 모든 중첩 타입이 유효한 fixture 데이터를 가지고 있는지 확인해주세요.
            """
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
