//
//  InterceptorConfig.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

// MARK: - InterceptorType

/// 인터셉터 타입
enum InterceptorType: String, CaseIterable, Sendable, Equatable, Identifiable {
    case consoleLogging = "console_logging"
    case auth
    case customHeader = "custom_header"
    case timestamp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .consoleLogging: return "콘솔 로깅"
        case .auth: return "인증 토큰"
        case .customHeader: return "커스텀 헤더"
        case .timestamp: return "타임스탬프"
        }
    }

    var description: String {
        switch self {
        case .consoleLogging:
            return "네트워크 요청/응답을 콘솔에 로깅합니다"
        case .auth:
            return "Authorization 헤더에 Bearer 토큰을 추가합니다"
        case .customHeader:
            return "X-Custom-Header를 요청에 추가합니다"
        case .timestamp:
            return "X-Timestamp 헤더를 현재 시간으로 추가합니다"
        }
    }

    var icon: String {
        switch self {
        case .consoleLogging: return "doc.text.magnifyingglass"
        case .auth: return "lock.shield"
        case .customHeader: return "tag"
        case .timestamp: return "clock"
        }
    }

    var order: Int {
        switch self {
        case .consoleLogging: return 4 // 마지막
        case .auth: return 1 // 첫번째
        case .customHeader: return 2
        case .timestamp: return 3
        }
    }
}

// MARK: - InterceptorConfig

/// 인터셉터 설정
struct InterceptorConfig: Equatable, Sendable {
    var enabledInterceptors: Set<InterceptorType>

    init(enabledInterceptors: Set<InterceptorType> = [.consoleLogging]) {
        self.enabledInterceptors = enabledInterceptors
    }

    func isEnabled(_ type: InterceptorType) -> Bool {
        enabledInterceptors.contains(type)
    }

    mutating func toggle(_ type: InterceptorType) {
        if enabledInterceptors.contains(type) {
            enabledInterceptors.remove(type)
        } else {
            enabledInterceptors.insert(type)
        }
    }

    var activeInterceptors: [InterceptorType] {
        enabledInterceptors.sorted { $0.order < $1.order }
    }

    var chainDescription: String {
        if enabledInterceptors.isEmpty {
            return "인터셉터 없음"
        }
        return activeInterceptors
            .map { "\($0.order). \($0.displayName)" }
            .joined(separator: " → ")
    }
}

// MARK: - InterceptorLog

/// 인터셉터 실행 로그
struct InterceptorLog: Equatable, Sendable, Identifiable {
    let id: UUID
    let timestamp: Date
    let interceptorType: InterceptorType
    let action: String
    let details: String

    init(
        interceptorType: InterceptorType,
        action: String,
        details: String
    ) {
        id = UUID()
        timestamp = Date()
        self.interceptorType = interceptorType
        self.action = action
        self.details = details
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

// MARK: - InterceptorTestResult

/// 인터셉터 테스트 결과
struct InterceptorTestResult: Equatable, Sendable {
    let success: Bool
    let requestURL: String
    let statusCode: Int?
    let duration: TimeInterval
    let logs: [InterceptorLog]
    let timestamp: Date

    init(
        success: Bool,
        requestURL: String,
        statusCode: Int?,
        duration: TimeInterval,
        logs: [InterceptorLog]
    ) {
        self.success = success
        self.requestURL = requestURL
        self.statusCode = statusCode
        self.duration = duration
        self.logs = logs
        timestamp = Date()
    }

    var formattedDuration: String {
        String(format: "%.3f초", duration)
    }

    var statusText: String {
        if let code = statusCode {
            return "HTTP \(code)"
        }
        return "실패"
    }
}
