//
//  NetworkConfiguration.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - NetworkConfiguration

/// 네트워크 서비스 설정
///
/// **주요 기능:**
/// - 재시도 정책 설정
/// - 타임아웃 설정
/// - 로깅 설정
public struct NetworkConfiguration: Sendable {
    /// 최대 재시도 횟수
    public let maxRetries: Int

    /// 재시도 간격 (초)
    public let retryDelay: TimeInterval

    /// 요청 타임아웃 (초)
    public let timeout: TimeInterval

    /// 로깅 활성화 여부
    public let enableLogging: Bool

    // MARK: - Initialization

    public init(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        timeout: TimeInterval = 30.0,
        enableLogging: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.timeout = timeout
        self.enableLogging = enableLogging
    }

    // MARK: - Presets

    /// 기본 설정
    public static let `default` = NetworkConfiguration(
        maxRetries: 3,
        retryDelay: 1.0,
        timeout: 30.0,
        enableLogging: true
    )

    /// 개발용 설정 (빠른 실패, 상세 로깅)
    public static let development = NetworkConfiguration(
        maxRetries: 1,
        retryDelay: 0.5,
        timeout: 15.0,
        enableLogging: true
    )

    /// 테스트용 설정 (재시도 없음, 로깅 없음)
    public static let test = NetworkConfiguration(
        maxRetries: 0,
        retryDelay: 0,
        timeout: 5.0,
        enableLogging: false
    )

    /// 안정성 우선 설정 (많은 재시도, 긴 타임아웃)
    public static let stable = NetworkConfiguration(
        maxRetries: 5,
        retryDelay: 2.0,
        timeout: 60.0,
        enableLogging: true
    )

    /// 속도 우선 설정 (적은 재시도, 짧은 타임아웃)
    public static let fast = NetworkConfiguration(
        maxRetries: 1,
        retryDelay: 0.1,
        timeout: 10.0,
        enableLogging: false
    )
}
