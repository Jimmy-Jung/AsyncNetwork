//
//  ErrorMapper.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - NetworkError

/// 통합 네트워크 에러
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

    /// 재시도 가능 여부
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

// MARK: - ErrorMapper

/// 에러 변환 및 매핑만 담당하는 구조체
///
/// **단일 책임:**
/// - 다양한 에러 타입을 통합 NetworkError로 변환
/// - 에러 컨텍스트 정보 추가
/// - 에러 로깅 및 분석
public struct ErrorMapper: Sendable {
    // MARK: - Properties

    private let enableLogging: Bool

    // MARK: - Initialization

    public init(enableLogging: Bool = true) {
        self.enableLogging = enableLogging
    }

    // MARK: - Public Methods

    /// 에러를 NetworkError로 매핑
    /// - Parameters:
    ///   - error: 원본 에러
    ///   - request: 관련된 API 요청 (옵션)
    /// - Returns: 매핑된 NetworkError
    public func mapError(_ error: Error, request: (any APIRequest)? = nil) -> NetworkError {
        let mappedError = performErrorMapping(error)

        if enableLogging {
            logErrorMapping(original: error, mapped: mappedError, request: request)
        }

        return mappedError
    }

    /// 에러가 재시도 가능한지 확인
    /// - Parameter error: 확인할 에러
    /// - Returns: 재시도 가능 여부
    public func isRetryable(_ error: Error) -> Bool {
        let mappedError = performErrorMapping(error)
        return mappedError.isRetryable
    }
}

// MARK: - ErrorMapper + Presets

public extension ErrorMapper {
    /// 기본 에러 매퍼 (로깅 활성화)
    static let `default` = ErrorMapper(enableLogging: true)

    /// 조용한 에러 매퍼 (로깅 비활성화)
    static let silent = ErrorMapper(enableLogging: false)
}

// MARK: - Private Methods

private extension ErrorMapper {
    /// 실제 에러 매핑 수행
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

    /// 에러 매핑 로깅
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
