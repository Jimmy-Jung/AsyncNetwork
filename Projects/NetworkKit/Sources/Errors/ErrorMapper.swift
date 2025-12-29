import Foundation

public enum NetworkError: Error, LocalizedError {
    case httpError(StatusCodeValidationError)
    case decodingError(DecodingError)
    case connectionError(URLError)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case let .httpError(error):
            return "HTTP Error: \(error.localizedDescription)"
        case let .decodingError(error):
            return "Decoding Error: \(error.localizedDescription)"
        case let .connectionError(error):
            return "Connection Error: \(error.localizedDescription)"
        case let .unknown(error):
            return "Unknown Error: \(error.localizedDescription)"
        }
    }

    public var isRetryable: Bool {
        switch self {
        case let .httpError(error):
            return error.statusCode >= 500
        case .connectionError:
            return true
        case .decodingError, .unknown:
            return false
        }
    }
}

public struct ErrorMapper: Sendable {
    private let enableLogging: Bool

    public init(enableLogging: Bool = true) {
        self.enableLogging = enableLogging
    }

    public func mapError(_ error: Error, request: (any APIRequest)? = nil) -> NetworkError {
        let mappedError = performErrorMapping(error)

        if enableLogging {
            logErrorMapping(original: error, mapped: mappedError, request: request)
        }

        return mappedError
    }

    public func isRetryable(_ error: Error) -> Bool {
        let mappedError = performErrorMapping(error)
        return mappedError.isRetryable
    }
}

public extension ErrorMapper {
    static let `default` = ErrorMapper(enableLogging: true)
    static let silent = ErrorMapper(enableLogging: false)
}

private extension ErrorMapper {
    func performErrorMapping(_ error: Error) -> NetworkError {
        switch error {
        case let statusError as StatusCodeValidationError:
            return .httpError(statusError)
        case let decodingError as DecodingError:
            return .decodingError(decodingError)
        case let urlError as URLError:
            return .connectionError(urlError)
        case let networkError as NetworkError:
            return networkError // 이미 매핑된 에러는 그대로 반환
        default:
            return .unknown(error)
        }
    }

    func logErrorMapping(original: Error, mapped: NetworkError, request: (any APIRequest)?) {
        #if DEBUG
            let requestInfo = request.map { "\($0)" } ?? "Unknown"
            print("🔄 [ErrorMapper] Mapped error for request: \(requestInfo)")
            print("   Original: \(original)")
            print("   Mapped: \(mapped)")
            print("   Retryable: \(mapped.isRetryable)")
        #endif
    }
}
