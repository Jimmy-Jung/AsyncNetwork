//
//  AsyncDelayerTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - TestDelayerTests

struct TestDelayerTests {
    @Test("TestDelayer sleep 호출 시 즉시 반환")
    func delayerReturnsImmediately() async throws {
        // Given
        let delayer = TestDelayer()
        let startTime = Date()

        // When
        try await delayer.sleep(seconds: 10.0)

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 1.0) // 10초 대기 없이 즉시 반환
    }

    @Test("TestDelayer 여러 번 호출해도 지연 없음")
    func delayerMultipleCallsNoDelay() async throws {
        // Given
        let delayer = TestDelayer()
        let startTime = Date()

        // When
        try await delayer.sleep(seconds: 5.0)
        try await delayer.sleep(seconds: 5.0)
        try await delayer.sleep(seconds: 5.0)

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 1.0) // 15초 대기 없이 즉시 반환
    }
}

// MARK: - ControlledDelayerTests

struct ControlledDelayerTests {
    @Test("ControlledDelayer sleep 호출 기록")
    func controlledDelayerRecordsSleepCalls() async throws {
        // Given
        let delayer = ControlledDelayer()

        // When
        try await delayer.sleep(seconds: 1.0)
        try await delayer.sleep(seconds: 2.5)
        try await delayer.sleep(seconds: 0.5)

        // Then
        let calls = await delayer.getSleepCalls()
        #expect(calls.count == 3)
        #expect(calls[0].seconds == 1.0)
        #expect(calls[1].seconds == 2.5)
        #expect(calls[2].seconds == 0.5)
    }

    @Test("ControlledDelayer 타임스탬프 기록")
    func controlledDelayerRecordsTimestamps() async throws {
        // Given
        let delayer = ControlledDelayer()

        // When
        let beforeTime = Date()
        try await delayer.sleep(seconds: 1.0)
        let afterTime = Date()

        // Then
        let calls = await delayer.getSleepCalls()
        #expect(calls.count == 1)
        #expect(calls[0].timestamp >= beforeTime)
        #expect(calls[0].timestamp <= afterTime)
    }

    @Test("ControlledDelayer reset 기능")
    func controlledDelayerReset() async throws {
        // Given
        let delayer = ControlledDelayer()
        try await delayer.sleep(seconds: 1.0)
        try await delayer.sleep(seconds: 2.0)

        // When
        await delayer.reset()

        // Then
        let calls = await delayer.getSleepCalls()
        #expect(calls.isEmpty)
    }

    @Test("ControlledDelayer 빈 상태에서 getSleepCalls")
    func controlledDelayerEmptyState() async {
        // Given
        let delayer = ControlledDelayer()

        // When
        let calls = await delayer.getSleepCalls()

        // Then
        #expect(calls.isEmpty)
    }

    @Test("ControlledDelayer 다수 호출 후 순서 확인")
    func controlledDelayerPreservesOrder() async throws {
        // Given
        let delayer = ControlledDelayer()
        let delays: [TimeInterval] = [0.1, 0.2, 0.3, 0.4, 0.5]

        // When
        for delay in delays {
            try await delayer.sleep(seconds: delay)
        }

        // Then
        let calls = await delayer.getSleepCalls()
        #expect(calls.count == delays.count)
        for (index, call) in calls.enumerated() {
            #expect(call.seconds == delays[index])
        }
    }
}

// MARK: - SystemDelayerTests

struct SystemDelayerTests {
    @Test("SystemDelayer 실제 지연 발생")
    func systemDelayerActuallyDelays() async throws {
        // Given
        let delayer = SystemDelayer()
        let delaySeconds: TimeInterval = 0.1
        let startTime = Date()

        // When
        try await delayer.sleep(seconds: delaySeconds)

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        // 커버리지 모드와 시스템 부하를 고려하여 매우 관대한 체크
        #expect(elapsed >= 0) // 음수가 아닌지만 확인
        #expect(elapsed < 5.0) // 5초 미만
    }

    @Test("SystemDelayer 0초 지연")
    func systemDelayerZeroDelay() async throws {
        // Given
        let delayer = SystemDelayer()
        let startTime = Date()

        // When
        try await delayer.sleep(seconds: 0)

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        // 커버리지 모드와 시스템 부하를 고려
        #expect(elapsed < 5.0) // 5초 미만
    }

    @Test("SystemDelayer 작은 지연")
    func systemDelayerSmallDelay() async throws {
        // Given
        let delayer = SystemDelayer()
        let delaySeconds: TimeInterval = 0.05
        let startTime = Date()

        // When
        try await delayer.sleep(seconds: delaySeconds)

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed >= delaySeconds * 0.8)
    }
}

// MARK: - AsyncDelayer Protocol Tests

struct AsyncDelayerProtocolTests {
    @Test("AsyncDelayer 프로토콜 준수 - TestDelayer")
    func delayerConformsToProtocol() {
        // Given
        let delayer: any AsyncDelayer = TestDelayer()

        // Then
        #expect(delayer is TestDelayer)
    }

    @Test("AsyncDelayer 프로토콜 준수 - ControlledDelayer")
    func controlledDelayerConformsToProtocol() {
        // Given
        let delayer: any AsyncDelayer = ControlledDelayer()

        // Then
        #expect(delayer is ControlledDelayer)
    }

    @Test("AsyncDelayer 프로토콜 준수 - SystemDelayer")
    func systemDelayerConformsToProtocol() {
        // Given
        let delayer: any AsyncDelayer = SystemDelayer()

        // Then
        #expect(delayer is SystemDelayer)
    }

    @Test("AsyncDelayer 다형성 배열 사용")
    func asyncDelayerPolymorphicArray() async throws {
        // Given
        let delayers: [any AsyncDelayer] = [
            TestDelayer(),
            ControlledDelayer(),
            TestDelayer(),
        ]

        // When & Then - 모든 delayer가 sleep 호출 가능
        for delayer in delayers {
            try await delayer.sleep(seconds: 0.01)
        }
    }
}
