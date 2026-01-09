//
//  Settings.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
import Foundation

// MARK: - NetworkConfigurationPreset

/// NetworkConfiguration 프리셋
enum NetworkConfigurationPreset: String, CaseIterable, Sendable {
    case development
    case `default`
    case stable
    case fast
    case test

    var displayName: String {
        switch self {
        case .development: return "Development"
        case .default: return "Default"
        case .stable: return "Stable"
        case .fast: return "Fast"
        case .test: return "Test"
        }
    }

    var description: String {
        switch self {
        case .development:
            return "개발용 설정 (재시도 1회, 빠른 타임아웃)"
        case .default:
            return "일반 사용 설정 (재시도 3회, 균형잡힌 타임아웃)"
        case .stable:
            return "안정적인 설정 (재시도 5회, 긴 타임아웃)"
        case .fast:
            return "빠른 응답 설정 (재시도 1회, 짧은 타임아웃)"
        case .test:
            return "테스트용 설정 (재시도 없음, 짧은 타임아웃)"
        }
    }

    var configuration: NetworkConfiguration {
        switch self {
        case .development: return .development
        case .default: return .default
        case .stable: return .stable
        case .fast: return .fast
        case .test: return .test
        }
    }
}

// MARK: - RetryPolicyPreset

/// RetryPolicy 프리셋
enum RetryPolicyPreset: String, CaseIterable, Sendable {
    case `default`
    case aggressive
    case conservative

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .aggressive: return "Aggressive"
        case .conservative: return "Conservative"
        }
    }

    var description: String {
        switch self {
        case .default:
            return "기본 재시도 정책 (최대 3회, 1초 지연)"
        case .aggressive:
            return "공격적 재시도 (최대 5회, 0.5초 지연)"
        case .conservative:
            return "보수적 재시도 (최대 1회, 2초 지연)"
        }
    }

    var maxRetries: Int {
        switch self {
        case .default: return 3
        case .aggressive: return 5
        case .conservative: return 1
        }
    }

    var configuration: RetryConfiguration {
        switch self {
        case .default: return .default
        case .aggressive: return .aggressive
        case .conservative: return .conservative
        }
    }
}

// MARK: - LoggingLevel

/// 로깅 레벨
enum LoggingLevel: String, CaseIterable, Sendable {
    case verbose
    case info
    case error
    case none

    var displayName: String {
        switch self {
        case .verbose: return "Verbose"
        case .info: return "Info"
        case .error: return "Error"
        case .none: return "None"
        }
    }

    var description: String {
        switch self {
        case .verbose: return "모든 네트워크 로그 출력"
        case .info: return "요청/응답 정보만 출력"
        case .error: return "에러만 출력"
        case .none: return "로그 비활성화"
        }
    }
}

// MARK: - NetworkStatus

/// 네트워크 상태
enum NetworkStatus: Equatable, Sendable {
    case connected(NetworkMonitor.ConnectionType)
    case disconnected

    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        }
    }

    var connectionTypeDescription: String {
        switch self {
        case let .connected(type):
            switch type {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .loopback: return "Loopback"
            case .unknown: return "Unknown"
            }
        case .disconnected:
            return "None"
        }
    }

    var isConnected: Bool {
        switch self {
        case .connected: return true
        case .disconnected: return false
        }
    }
}
