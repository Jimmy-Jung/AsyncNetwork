//
//  RetryRule.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - RetryRule Protocol

/// 재시도 가능 여부를 판단하는 규칙
///
/// **동작 원리:**
/// - 여러 룰이 체인 형태로 동작합니다.
/// - `nil` 반환: 이 룰에서는 판단할 수 없음 (다음 룰로 넘어감)
/// - `true` 반환: 재시도 가능
/// - `false` 반환: 재시도 불가능 (즉시 중단)
public protocol RetryRule: Sendable {
    /// 에러를 분석하여 재시도 여부를 결정합니다.
    /// - Parameter error: 발생한 에러
    /// - Returns: 재시도 가능 여부 (nil이면 판단 유보)
    func shouldRetry(error: Error) -> Bool?
}

// MARK: - Standard Rules

/// URLError 기반 재시도 룰
/// - 타임아웃, 연결 유실 등 네트워크 레벨 에러 처리
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
            .notConnectedToInternet
        ]

        return retryableCodes.contains(urlError.code)
    }
}

/// 서버 에러(5xx) 기반 재시도 룰
/// - 500번대 에러는 일시적일 수 있으므로 재시도
public struct ServerErrorRetryRule: RetryRule {
    public init() {}

    public func shouldRetry(error: Error) -> Bool? {
        // StatusCodeValidator에서 발생하는 에러 체크
        if let statusError = error as? StatusCodeValidationError {
            switch statusError {
            case .serverError: return true
            case .clientError, .invalidStatusCode, .unknownError: return false
            }
        }
        return nil
    }
}
