//
//  StatusCodeValidator.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - StatusCodeValidationError

/// 상태 코드 검증 에러
public enum StatusCodeValidationError: Error, LocalizedError {
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

// MARK: - StatusCodeValidator

/// HTTP 상태 코드 검증만 담당하는 구조체
///
/// **단일 책임:**
/// - HTTP 상태 코드 검증
/// - 성공/실패 상태 코드 분류
/// - 상태 코드별 에러 생성
public struct StatusCodeValidator: Sendable {
    // MARK: - Properties

    private let acceptableStatusCodes: Set<Int>

    // MARK: - Initialization

    public init(acceptableStatusCodes: Set<Int> = Set(200 ... 299)) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }

    // MARK: - Public Methods

    /// HTTP 상태 코드 검증
    /// - Parameter response: 검증할 HTTPResponse
    /// - Returns: 검증된 Response (성공 시)
    /// - Throws: StatusCodeValidationError (실패 시)
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

    /// 상태 코드가 성공 범위인지 확인
    /// - Parameter statusCode: 확인할 상태 코드
    /// - Returns: 성공 여부
    public func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        return acceptableStatusCodes.contains(statusCode)
    }

    /// 상태 코드가 재시도 가능한 에러인지 확인
    /// - Parameter statusCode: 확인할 상태 코드
    /// - Returns: 재시도 가능 여부
    public func isRetryableStatusCode(_ statusCode: Int) -> Bool {
        // 5xx 서버 에러는 재시도 가능
        return statusCode >= 500 && statusCode < 600
    }
}

// MARK: - StatusCodeValidator + Presets

public extension StatusCodeValidator {
    /// 기본 설정 (200-299)
    static let `default` = StatusCodeValidator()

    /// 관대한 설정 (200-399)
    static let lenient = StatusCodeValidator(
        acceptableStatusCodes: Set(200 ... 399)
    )

    /// 엄격한 설정 (200, 201, 204만 허용)
    static let strict = StatusCodeValidator(
        acceptableStatusCodes: Set([200, 201, 204])
    )

    /// 커스텀 상태 코드 설정
    static func custom(_ statusCodes: Set<Int>) -> StatusCodeValidator {
        return StatusCodeValidator(acceptableStatusCodes: statusCodes)
    }
}

// MARK: - Private Methods

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
