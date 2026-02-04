import SwiftDiagnostics

/// 매크로 에러 및 진단 메시지
///
/// TCA 스타일의 상세한 에러 메시지와 해결책을 제공합니다.
public enum MacroError: Error, DiagnosticMessage {
    // MARK: - Declaration Errors

    /// struct가 아닌 타입에 매크로를 적용했을 때
    case onlyApplicableToStruct

    /// 매크로에 인자가 없을 때
    case missingArguments

    // MARK: - Argument Errors

    /// 필수 인자가 누락되었을 때
    case missingRequiredArgument(String, expectedType: String)

    /// 유효하지 않은 인자 값
    case invalidArgument(String, reason: String, suggestion: String?)

    /// 지원하지 않는 인자 타입
    case unsupportedArgumentType(argumentName: String, givenType: String, expectedType: String)

    // MARK: - Validation Errors

    /// Path Parameter 검증 실패
    case pathParameterNotFound(parameterName: String, availableParameters: [String])

    /// Property Wrapper 타입 불일치
    case propertyWrapperTypeMismatch(propertyName: String, wrapperType: String, expectedType: String)

    /// 동적 메서드가 지원되지 않는 타입
    case unsupportedDynamicMethod(propertyName: String, givenType: String)

    // MARK: - DiagnosticMessage Protocol

    public var message: String {
        switch self {
        case .onlyApplicableToStruct:
            return """
            @APIRequest는 struct에만 적용할 수 있습니다

            💡 이유: APIRequest는 값 타입(Value Type)으로 설계되어야 합니다.
               class는 참조 타입이므로 의도하지 않은 공유 상태를 유발할 수 있습니다.

            ✅ 해결 방법: 선언을 struct로 변경하세요.
            """

        case .missingArguments:
            return """
            @APIRequest 매크로에 필수 인자가 필요합니다

            💡 필수 인자:
               - response: 응답 타입 (예: User.self)
               - baseURL: 기본 URL (예: "https://api.example.com")
               - path: 요청 경로 (예: "/users")
               - method: HTTP 메서드 (예: .get)

            ✅ 예제:
               @APIRequest(
                   response: User.self,
                   baseURL: "https://api.example.com",
                   path: "/users",
                   method: .get
               )
            """

        case let .missingRequiredArgument(arg, expectedType):
            return """
            @APIRequest에 필수 인자 '\(arg)'가 누락되었습니다

            💡 예상 타입: \(expectedType)

            ✅ 해결 방법: '\(arg)' 인자를 추가하세요.
               예: \(arg): \(defaultValue(for: arg, type: expectedType))
            """

        case let .invalidArgument(arg, reason, suggestion):
            var message = """
            @APIRequest의 '\(arg)' 인자가 유효하지 않습니다

            ❌ 문제: \(reason)
            """
            if let suggestion = suggestion {
                message += """


                ✅ 해결 방법: \(suggestion)
                """
            }
            return message

        case let .unsupportedArgumentType(argumentName, givenType, expectedType):
            return """
            @APIRequest의 '\(argumentName)' 인자 타입이 올바르지 않습니다

            ❌ 현재 타입: \(givenType)
            💡 예상 타입: \(expectedType)

            ✅ 해결 방법: 타입을 \(expectedType)으로 변경하세요.
            """

        case let .pathParameterNotFound(parameterName, availableParameters):
            let available = availableParameters.isEmpty
                ? "없음"
                : availableParameters.map { "{\($0)}" }.joined(separator: ", ")

            return """
            Path에 정의되지 않은 Parameter '\(parameterName)'를 사용하려고 합니다

            💡 Path에 정의된 Parameter: \(available)

            ✅ 해결 방법:
               1. Path에 {\(parameterName)}를 추가하거나
               2. @PathParameter 프로퍼티 이름을 Path의 Parameter와 일치시키세요
            """

        case let .propertyWrapperTypeMismatch(propertyName, wrapperType, expectedType):
            return """
            '\(propertyName)' 프로퍼티의 타입이 Property Wrapper와 맞지 않습니다

            ❌ Wrapper: \(wrapperType)
            💡 예상 타입: \(expectedType)

            ✅ 해결 방법:
               - @QueryParameter: String, Int, Bool, Double 등
               - @PathParameter: String (필수)
               - @RequestBody: Encodable 준수 타입
            """

        case let .unsupportedDynamicMethod(propertyName, givenType):
            return """
            '\(propertyName)'의 타입 '\(givenType)'는 동적 메서드로 사용할 수 없습니다

            💡 지원되는 타입: HTTPMethod, Optional<HTTPMethod>

            ✅ 해결 방법:
               var \(propertyName): HTTPMethod
            """
        }
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "AsyncNetworkMacros", id: "\(self)")
    }

    public var severity: DiagnosticSeverity {
        switch self {
        case .onlyApplicableToStruct,
             .missingArguments,
             .missingRequiredArgument,
             .invalidArgument,
             .unsupportedArgumentType,
             .unsupportedDynamicMethod:
            return .error

        case .pathParameterNotFound,
             .propertyWrapperTypeMismatch:
            // ValidationLevel에 따라 조절 가능
            return .warning
        }
    }

    // MARK: - Helper: Default Values

    private func defaultValue(for argument: String, type: String) -> String {
        switch argument {
        case "response":
            return "MyResponse.self"
        case "baseURL":
            return "\"https://api.example.com\""
        case "path":
            return "\"/endpoint\""
        case "method":
            return ".get"
        default:
            return "/* \(type) 값 */"
        }
    }
}
