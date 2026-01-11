//
//  ErrorSimulator.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import Foundation

// MARK: - SimulatedErrorType

/// 시뮬레이션할 에러 타입
enum SimulatedErrorType: String, CaseIterable, Sendable, Equatable {
    case none
    case networkConnectionLost
    case timeout
    case notFound
    case serverError
    case unauthorized
    case badRequest

    var displayName: String {
        switch self {
        case .none: return "정상"
        case .networkConnectionLost: return "네트워크 연결 끊김"
        case .timeout: return "타임아웃"
        case .notFound: return "404 Not Found"
        case .serverError: return "500 Server Error"
        case .unauthorized: return "401 Unauthorized"
        case .badRequest: return "400 Bad Request"
        }
    }

    var description: String {
        switch self {
        case .none:
            return "정상 동작 - 에러 시뮬레이션 없음"
        case .networkConnectionLost:
            return "네트워크 연결이 끊어진 상황을 시뮬레이션합니다"
        case .timeout:
            return "요청 시간 초과 상황을 시뮬레이션합니다"
        case .notFound:
            return "404 리소스를 찾을 수 없는 상황을 시뮬레이션합니다"
        case .serverError:
            return "500 서버 내부 에러 상황을 시뮬레이션합니다"
        case .unauthorized:
            return "401 인증 실패 상황을 시뮬레이션합니다"
        case .badRequest:
            return "400 잘못된 요청 상황을 시뮬레이션합니다"
        }
    }

    var shouldRetry: Bool {
        switch self {
        case .none: return false
        case .networkConnectionLost: return true
        case .timeout: return true
        case .notFound: return false
        case .serverError: return true
        case .unauthorized: return false
        case .badRequest: return false
        }
    }

    var icon: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .networkConnectionLost: return "wifi.slash"
        case .timeout: return "clock.badge.exclamationmark"
        case .notFound: return "doc.questionmark"
        case .serverError: return "server.rack"
        case .unauthorized: return "lock.fill"
        case .badRequest: return "exclamationmark.triangle"
        }
    }
}

// MARK: - ErrorSimulationResult

/// 에러 시뮬레이션 결과
enum ErrorSimulationResult: Equatable, Sendable {
    case success(url: String, statusCode: Int, duration: TimeInterval)
    case failure(url: String, errorType: SimulatedErrorType, attempt: Int, willRetry: Bool, duration: TimeInterval)

    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    var url: String {
        switch self {
        case let .success(url, _, _): return url
        case let .failure(url, _, _, _, _): return url
        }
    }

    var statusCode: Int? {
        switch self {
        case let .success(_, statusCode, _): return statusCode
        case .failure: return nil
        }
    }

    var errorType: SimulatedErrorType? {
        switch self {
        case .success: return nil
        case let .failure(_, errorType, _, _, _): return errorType
        }
    }

    var attempt: Int? {
        switch self {
        case .success: return nil
        case let .failure(_, _, attempt, _, _): return attempt
        }
    }

    var willRetry: Bool? {
        switch self {
        case .success: return nil
        case let .failure(_, _, _, willRetry, _): return willRetry
        }
    }

    var duration: TimeInterval {
        switch self {
        case let .success(_, _, duration): return duration
        case let .failure(_, _, _, _, duration): return duration
        }
    }

    var displayMessage: String {
        switch self {
        case let .success(_, statusCode, duration):
            return "✅ 성공 (HTTP \(statusCode), \(String(format: "%.2f", duration))초)"
        case let .failure(_, errorType, attempt, willRetry, duration):
            let retryText = willRetry ? "재시도 예정" : "재시도 불가"
            return "❌ 실패 (\(errorType.displayName), 시도 \(attempt), \(retryText), \(String(format: "%.2f", duration))초)"
        }
    }
}
