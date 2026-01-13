//
//  SettingsTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//  Updated: 2026/01/12 - Removed legacy types
//

import Foundation
@testable import AsyncNetworkSampleApp
import Testing

/// Settings 도메인 모델 테스트
@Suite("Settings 도메인 모델")
struct SettingsTests {
    // MARK: - ETag Cache Tests

    @Test("ETagCacheCapacityPreset은 모든 프리셋을 제공한다")
    func etagCacheCapacityPresetProvidesAllPresets() {
        let presets = ETagCacheCapacityPreset.allCases

        #expect(presets.count == 4)
        #expect(presets.contains(.small))
        #expect(presets.contains(.medium))
        #expect(presets.contains(.large))
        #expect(presets.contains(.custom))
    }

    @Test("ETagCacheCapacityPreset의 displayName은 명확하다")
    func etagCacheCapacityPresetDisplayNamesAreClear() {
        #expect(ETagCacheCapacityPreset.small.displayName == "작음 (Small)")
        #expect(ETagCacheCapacityPreset.medium.displayName == "중간 (Medium)")
        #expect(ETagCacheCapacityPreset.large.displayName == "큼 (Large)")
        #expect(ETagCacheCapacityPreset.custom.displayName == "커스텀")
    }

    @Test("ETagCacheCapacityPreset의 capacity는 올바른 값을 반환한다")
    func etagCacheCapacityPresetReturnsCorrectCapacity() {
        #expect(ETagCacheCapacityPreset.small.capacity == 50)
        #expect(ETagCacheCapacityPreset.medium.capacity == 200)
        #expect(ETagCacheCapacityPreset.large.capacity == 500)
    }

    @Test("ETagCacheUsage는 사용률을 올바르게 계산한다")
    func etagCacheUsageCalculatesUsagePercentageCorrectly() {
        let usage = ETagCacheUsage(currentCount: 50, capacity: 200)

        #expect(usage.usagePercentage == 25.0)
    }

    @Test("ETagCacheUsage는 0 용량일 때 0%를 반환한다")
    func etagCacheUsageReturnsZeroPercentageWhenCapacityIsZero() {
        let usage = ETagCacheUsage(currentCount: 10, capacity: 0)

        #expect(usage.usagePercentage == 0.0)
    }

    @Test("ETagCacheUsage.formattedUsage는 읽기 쉬운 형식을 반환한다")
    func etagCacheUsageFormattedUsageIsReadable() {
        let usage = ETagCacheUsage(currentCount: 50, capacity: 200)

        let formatted = usage.formattedUsage
        #expect(formatted == "50 / 200")
    }

    @Test("ETagCacheUsage.formattedPercentage는 읽기 쉬운 형식을 반환한다")
    func etagCacheUsageFormattedPercentageIsReadable() {
        let usage = ETagCacheUsage(currentCount: 50, capacity: 200)

        let formatted = usage.formattedPercentage
        #expect(formatted == "25%")
    }

    // MARK: - RetryPolicyPreset Tests

    @Test("RetryPolicyPreset은 모든 프리셋을 제공한다")
    func retryPolicyPresetProvidesAllPresets() {
        let presets = RetryPolicyPreset.allCases

        #expect(presets.count == 4)
        #expect(presets.contains(.standard))
        #expect(presets.contains(.quick))
        #expect(presets.contains(.patient))
        #expect(presets.contains(.none))
    }

    @Test("RetryPolicyPreset의 displayName은 명확하다")
    func retryPolicyPresetDisplayNamesAreClear() {
        #expect(RetryPolicyPreset.standard.displayName == "표준 (Standard)")
        #expect(RetryPolicyPreset.quick.displayName == "빠름 (Quick)")
        #expect(RetryPolicyPreset.patient.displayName == "느림 (Patient)")
        #expect(RetryPolicyPreset.none.displayName == "재시도 없음")
    }

    @Test("RetryPolicyPreset의 maxRetries는 올바른 값을 반환한다")
    func retryPolicyPresetReturnsCorrectMaxRetries() {
        #expect(RetryPolicyPreset.standard.maxRetries == 3)
        #expect(RetryPolicyPreset.quick.maxRetries == 5)
        #expect(RetryPolicyPreset.patient.maxRetries == 1)
        #expect(RetryPolicyPreset.none.maxRetries == 0)
    }

    // MARK: - LoggingLevel Tests

    @Test("LoggingLevel은 모든 레벨을 제공한다")
    func loggingLevelProvidesAllLevels() {
        let levels = LoggingLevel.allCases

        #expect(levels.count == 4)
        #expect(levels.contains(.verbose))
        #expect(levels.contains(.info))
        #expect(levels.contains(.error))
        #expect(levels.contains(.none))
    }

    @Test("LoggingLevel의 displayName은 명확하다")
    func loggingLevelDisplayNamesAreClear() {
        #expect(LoggingLevel.verbose.displayName == "Verbose")
        #expect(LoggingLevel.info.displayName == "Info")
        #expect(LoggingLevel.error.displayName == "Error")
        #expect(LoggingLevel.none.displayName == "None")
    }

    // MARK: - ConnectionStatus Tests (NetworkMonitorState.swift)

    @Test("ConnectionStatus는 연결 타입을 올바르게 표현한다")
    func connectionStatusRepresentsConnectionTypesCorrectly() {
        #expect(ConnectionStatus.connected.displayName == "연결됨")
        #expect(ConnectionStatus.disconnected.displayName == "연결 끊김")
        #expect(ConnectionStatus.unknown.displayName == "알 수 없음")
    }

    @Test("ConnectionStatus는 연결 타입 아이콘을 제공한다")
    func connectionStatusProvidesIcons() {
        #expect(ConnectionStatus.connected.icon == "wifi")
        #expect(ConnectionStatus.disconnected.icon == "wifi.slash")
        #expect(ConnectionStatus.unknown.icon == "questionmark.circle")
    }

    @Test("ConnectionStatus는 색상 정보를 제공한다")
    func connectionStatusProvidesColorInfo() {
        #expect(ConnectionStatus.connected.color == "green")
        #expect(ConnectionStatus.disconnected.color == "red")
        #expect(ConnectionStatus.unknown.color == "gray")
    }
}
