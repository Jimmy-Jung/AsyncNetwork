//
//  AsyncDelayer.swift
//  QubeNetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - AsyncDelayer Protocol

/// 비동기 지연 실행을 위한 프로토콜
///
/// **목적:**
/// - Clocks 의존성 제거
/// - 테스트 가능한 지연 로직 제공
/// - 재시도 정책에서 사용
public protocol AsyncDelayer: Sendable {
    /// 지정된 시간만큼 대기
    /// - Parameter seconds: 대기 시간 (초)
    func sleep(seconds: TimeInterval) async throws
}

// MARK: - SystemDelayer

/// 시스템 Task.sleep을 사용하는 실제 구현체
public struct SystemDelayer: AsyncDelayer {
    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - TestDelayer

/// 테스트용 즉시 리턴하는 구현체
public struct TestDelayer: AsyncDelayer {
    public init() {}

    public func sleep(seconds _: TimeInterval) async throws {
        // 테스트에서는 즉시 리턴
    }
}

// MARK: - ControlledDelayer

/// 테스트에서 지연 호출을 추적할 수 있는 구현체
public actor ControlledDelayer: AsyncDelayer {
    private var sleepCalls: [(seconds: TimeInterval, timestamp: Date)] = []

    public init() {}

    public func sleep(seconds: TimeInterval) async throws {
        sleepCalls.append((seconds: seconds, timestamp: Date()))
    }

    /// 호출 기록 조회
    public func getSleepCalls() -> [(seconds: TimeInterval, timestamp: Date)] {
        return sleepCalls
    }

    /// 호출 기록 초기화
    public func reset() {
        sleepCalls.removeAll()
    }
}
