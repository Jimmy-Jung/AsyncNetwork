import Foundation

public enum StatusCodeValidationError: Error, LocalizedError, Equatable {
    case invalidStatusCode(Int, Data?)
    case clientError(Int, Data?)
    case serverError(Int, Data?)
    case unknownError(Int, Data?)

    public var errorDescription: String? {
        switch self {
        case let .invalidStatusCode(code, _):
            return "Invalid status code: \(code)"
        case let .clientError(code, _):
            return "Client error: \(code)"
        case let .serverError(code, _):
            return "Server error: \(code)"
        case let .unknownError(code, _):
            return "Unknown error: \(code)"
        }
    }

    public var statusCode: Int {
        switch self {
        case let .invalidStatusCode(code, _),
             let .clientError(code, _),
             let .serverError(code, _),
             let .unknownError(code, _):
            return code
        }
    }

    public var responseData: Data? {
        switch self {
        case let .invalidStatusCode(_, data),
             let .clientError(_, data),
             let .serverError(_, data),
             let .unknownError(_, data):
            return data
        }
    }
}

public struct StatusCodeValidator: Sendable {
    private let acceptableStatusCodes: Set<Int>

    public init(acceptableStatusCodes: Set<Int> = Set(200 ... 299)) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }

    public func validate(_ response: HTTPResponse) throws -> HTTPResponse {
        let statusCode = response.statusCode

        logValidation(statusCode: statusCode)

        if acceptableStatusCodes.contains(statusCode) {
            logValidationSuccess(statusCode: statusCode)
            return response
        }

        let error = createValidationError(statusCode: statusCode, data: response.data)
        logValidationFailure(error: error)
        throw error
    }

    public func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        return acceptableStatusCodes.contains(statusCode)
    }

    public func isRetryableStatusCode(_ statusCode: Int) -> Bool {
        return statusCode >= 500 && statusCode < 600
    }
}

public extension StatusCodeValidator {
    static let `default` = StatusCodeValidator()

    static let lenient = StatusCodeValidator(
        acceptableStatusCodes: Set(200 ... 399)
    )

    static let strict = StatusCodeValidator(
        acceptableStatusCodes: Set([200, 201, 204])
    )

    static func custom(_ statusCodes: Set<Int>) -> StatusCodeValidator {
        return StatusCodeValidator(acceptableStatusCodes: statusCodes)
    }
}

private extension StatusCodeValidator {
    func createValidationError(statusCode: Int, data: Data) -> StatusCodeValidationError {
        switch statusCode {
        case 100 ..< 200:
            return .invalidStatusCode(statusCode, data)
        case 400 ..< 500:
            return .clientError(statusCode, data)
        case 500 ..< 600:
            return .serverError(statusCode, data)
        default:
            return .unknownError(statusCode, data)
        }
    }

    func logValidation(statusCode: Int) {
        #if DEBUG
            print("🔍 [StatusCodeValidator] Validating status code: \(statusCode)")
        #endif
    }

    func logValidationSuccess(statusCode: Int) {
        #if DEBUG
            print("✅ [StatusCodeValidator] Status code \(statusCode) is valid")
        #endif
    }

    func logValidationFailure(error: StatusCodeValidationError) {
        #if DEBUG
            print("❌ [StatusCodeValidator] Status code validation failed: \(error)")
        #endif
    }
}
