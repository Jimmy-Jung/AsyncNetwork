import Foundation

/// 재시도 가능 여부를 판단하는 규칙
///
/// 여러 룰이 체인 형태로 동작합니다:
/// - `nil` 반환: 다음 룰로 넘어감
/// - `true` 반환: 재시도 가능
/// - `false` 반환: 즉시 중단
public protocol RetryRule: Sendable {
    func shouldRetry(error: Error) -> Bool?
}

public struct URLErrorRetryRule: RetryRule {
    public init() {}

    public func shouldRetry(error: Error) -> Bool? {
        guard let urlError = error as? URLError else { return nil }

        let retryableCodes: Set<URLError.Code> = [
            .networkConnectionLost,
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .dnsLookupFailed,
            .notConnectedToInternet,
        ]

        return retryableCodes.contains(urlError.code)
    }
}

public struct ServerErrorRetryRule: RetryRule {
    public init() {}

    public func shouldRetry(error: Error) -> Bool? {
        if let statusError = error as? StatusCodeValidationError {
            switch statusError {
            case .serverError: return true
            case .clientError, .invalidStatusCode, .unknownError: return false
            }
        }
        return nil
    }
}
