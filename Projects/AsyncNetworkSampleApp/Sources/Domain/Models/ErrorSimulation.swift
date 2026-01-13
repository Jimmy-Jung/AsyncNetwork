//
//  ErrorSimulation.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

// MARK: - ErrorType

/// 시뮬레이션 가능한 에러 타입
enum ErrorType: String, CaseIterable, Sendable, Equatable, Identifiable {
    case timeout
    case networkFailure
    case serverError
    case invalidResponse
    case unauthorized
    case notFound

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .timeout: return "Timeout"
        case .networkFailure: return "Network Failure"
        case .serverError: return "Server Error (500)"
        case .invalidResponse: return "Invalid Response"
        case .unauthorized: return "Unauthorized (401)"
        case .notFound: return "Not Found (404)"
        }
    }

    var description: String {
        switch self {
        case .timeout:
            return "요청 시간 초과"
        case .networkFailure:
            return "네트워크 연결 실패"
        case .serverError:
            return "서버 내부 오류"
        case .invalidResponse:
            return "잘못된 응답 형식"
        case .unauthorized:
            return "인증 실패"
        case .notFound:
            return "리소스를 찾을 수 없음"
        }
    }

    var icon: String {
        switch self {
        case .timeout: return "clock.badge.exclamationmark"
        case .networkFailure: return "wifi.slash"
        case .serverError: return "exclamationmark.triangle.fill"
        case .invalidResponse: return "exclamationmark.bubble"
        case .unauthorized: return "lock.slash"
        case .notFound: return "questionmark.folder"
        }
    }

    var statusCode: Int? {
        switch self {
        case .serverError: return 500
        case .unauthorized: return 401
        case .notFound: return 404
        default: return nil
        }
    }

    func generateError() -> Error {
        switch self {
        case .timeout:
            return NSError(domain: "AsyncNetworkDemo", code: -1001, userInfo: [
                NSLocalizedDescriptionKey: "The request timed out."
            ])
        case .networkFailure:
            return NSError(domain: "AsyncNetworkDemo", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
            ])
        case .serverError:
            return NSError(domain: "AsyncNetworkDemo", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Internal Server Error"
            ])
        case .invalidResponse:
            return NSError(domain: "AsyncNetworkDemo", code: -1011, userInfo: [
                NSLocalizedDescriptionKey: "Invalid response received from server."
            ])
        case .unauthorized:
            return NSError(domain: "AsyncNetworkDemo", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Unauthorized: Authentication required."
            ])
        case .notFound:
            return NSError(domain: "AsyncNetworkDemo", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Not Found: Resource does not exist."
            ])
        }
    }
}

// MARK: - ErrorSimulation

/// 에러 시뮬레이션 설정
struct ErrorSimulation: Equatable, Sendable {
    var errorType: ErrorType
    var failureRate: Double // 0.0 ~ 1.0

    init(
        errorType: ErrorType = .timeout,
        failureRate: Double = 0.8
    ) {
        self.errorType = errorType
        self.failureRate = max(0.0, min(1.0, failureRate))
    }

    func shouldFail() -> Bool {
        return Double.random(in: 0 ... 1) < failureRate
    }
}

// MARK: - ErrorSimulationAttempt

/// 에러 시뮬레이션 시도 정보
struct ErrorSimulationAttempt: Equatable, Sendable, Identifiable {
    let id: UUID
    let attemptNumber: Int
    let timestamp: Date
    let success: Bool
    let error: String?
    let errorType: ErrorType?
    let delay: TimeInterval?

    init(
        attemptNumber: Int,
        timestamp: Date = Date(),
        success: Bool,
        error: String? = nil,
        errorType: ErrorType? = nil,
        delay: TimeInterval? = nil
    ) {
        id = UUID()
        self.attemptNumber = attemptNumber
        self.timestamp = timestamp
        self.success = success
        self.error = error
        self.errorType = errorType
        self.delay = delay
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    var formattedDelay: String? {
        guard let delay = delay else { return nil }
        return String(format: "%.2f초", delay)
    }
}

// MARK: - ErrorSimulationTimeline

/// 에러 시뮬레이션 타임라인
struct ErrorSimulationTimeline: Equatable, Sendable {
    let errorType: ErrorType
    let failureRate: Double
    let maxRetries: Int
    var attempts: [ErrorSimulationAttempt]
    let startTime: Date
    var endTime: Date?

    init(errorType: ErrorType, failureRate: Double, maxRetries: Int) {
        self.errorType = errorType
        self.failureRate = failureRate
        self.maxRetries = maxRetries
        attempts = []
        startTime = Date()
        endTime = nil
    }

    mutating func addAttempt(_ attempt: ErrorSimulationAttempt) {
        attempts.append(attempt)
        if attempt.success || attempts.count > maxRetries {
            endTime = Date()
        }
    }

    var totalDuration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        String(format: "%.2f초", totalDuration)
    }

    var successRate: Double {
        guard !attempts.isEmpty else { return 0 }
        let successCount = attempts.filter { $0.success }.count
        return Double(successCount) / Double(attempts.count)
    }

    var isCompleted: Bool {
        endTime != nil
    }

    var finalSuccess: Bool {
        attempts.last?.success ?? false
    }
}
