//
//  Settings.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
import Foundation

// MARK: - ETag Cache Settings

/// ETag 캐시 용량 프리셋
enum ETagCacheCapacityPreset: String, CaseIterable, Sendable, Identifiable, Equatable {
    case small
    case medium
    case large
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "작음 (Small)"
        case .medium: return "중간 (Medium)"
        case .large: return "큼 (Large)"
        case .custom: return "커스텀"
        }
    }
    
    var description: String {
        switch self {
        case .small: return "최대 50개 URL"
        case .medium: return "최대 200개 URL"
        case .large: return "최대 500개 URL"
        case .custom: return "사용자 정의 용량"
        }
    }
    
    var capacity: Int {
        switch self {
        case .small: return 50
        case .medium: return 200
        case .large: return 500
        case .custom: return 200 // 기본값
        }
    }
}

/// ETag 캐시 사용량 정보
struct ETagCacheUsage: Equatable, Sendable {
    let currentCount: Int
    let capacity: Int
    
    var usageRatio: Double {
        guard capacity > 0 else { return 0 }
        return Double(currentCount) / Double(capacity)
    }
    
    var usagePercentage: Double {
        guard capacity > 0 else { return 0 }
        return Double(currentCount) / Double(capacity) * 100
    }
    
    var formattedUsage: String {
        "\(currentCount) / \(capacity)"
    }
    
    var formattedPercentage: String {
        String(format: "%.0f%%", usagePercentage)
    }
}

// MARK: - Log Level Settings

// MARK: - RetryPolicyPreset

/// RetryPolicy 프리셋
enum RetryPolicyPreset: String, CaseIterable, Sendable, Identifiable, Equatable {
    case standard
    case quick
    case patient
    case none
    case custom
    
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "표준 (Standard)"
        case .quick: return "빠름 (Quick)"
        case .patient: return "느림 (Patient)"
        case .none: return "재시도 없음"
        case .custom: return "커스텀"
        }
    }

    var description: String {
        switch self {
        case .standard:
            return "표준 재시도: 3회, 1초 간격 (~1초, ~2초, ~4초)"
        case .quick:
            return "빠른 재시도: 5회, 0.5초 간격 (~0.5초, ~1초, ~2초, ~4초, ~8초)"
        case .patient:
            return "느린 재시도: 1회, 2초 간격 (~2초)"
        case .none:
            return "재시도하지 않음"
        case .custom:
            return "사용자 정의 설정"
        }
    }

    var maxRetries: Int {
        switch self {
        case .standard: return 3
        case .quick: return 5
        case .patient: return 1
        case .none: return 0
        case .custom: return 3
        }
    }
    
    var baseDelay: TimeInterval {
        switch self {
        case .standard: return 1.0
        case .quick: return 0.5
        case .patient: return 2.0
        case .none: return 0
        case .custom: return 1.0
        }
    }

    var configuration: RetryConfiguration {
        switch self {
        case .standard: return .standard
        case .quick: return .quick
        case .patient: return .patient
        case .none: return RetryConfiguration(maxRetries: 0, baseDelay: 0, maxDelay: 0, jitterRange: 0...0)
        case .custom: return .standard // 나중에 커스텀 구현 가능
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
