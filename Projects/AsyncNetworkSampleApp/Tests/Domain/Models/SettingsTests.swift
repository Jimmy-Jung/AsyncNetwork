//
//  SettingsTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

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
        #expect(formatted == "50 / 200 URLs")
    }
    
    @Test("ETagCacheUsage.formattedPercentage는 읽기 쉬운 형식을 반환한다")
    func etagCacheUsageFormattedPercentageIsReadable() {
        let usage = ETagCacheUsage(currentCount: 50, capacity: 200)
        
        let formatted = usage.formattedPercentage
        #expect(formatted == "25.0%")
    }
    
    // MARK: - HTTP Cache (CacheCapacityPreset) Tests
    
    @Test("CacheCapacityPreset은 모든 프리셋을 제공한다")
    func cacheCapacityPresetProvidesAllPresets() {
        let presets = CacheCapacityPreset.allCases
        
        #expect(presets.count == 4)
        #expect(presets.contains(.small))
        #expect(presets.contains(.medium))
        #expect(presets.contains(.large))
        #expect(presets.contains(.custom))
    }
    
    @Test("CacheCapacityPreset의 displayName은 명확하다")
    func cacheCapacityPresetDisplayNamesAreClear() {
        #expect(CacheCapacityPreset.small.displayName == "작음 (Small)")
        #expect(CacheCapacityPreset.medium.displayName == "중간 (Medium)")
        #expect(CacheCapacityPreset.large.displayName == "큼 (Large)")
        #expect(CacheCapacityPreset.custom.displayName == "커스텀")
    }
    
    @Test("CacheCapacityPreset의 memoryCapacity는 올바른 값을 반환한다")
    func cacheCapacityPresetReturnsCorrectMemoryCapacity() {
        #expect(CacheCapacityPreset.small.memoryCapacity == 4 * 1024 * 1024) // 4MB
        #expect(CacheCapacityPreset.medium.memoryCapacity == 10 * 1024 * 1024) // 10MB
        #expect(CacheCapacityPreset.large.memoryCapacity == 20 * 1024 * 1024) // 20MB
    }
    
    @Test("CacheCapacityPreset의 diskCapacity는 올바른 값을 반환한다")
    func cacheCapacityPresetReturnsCorrectDiskCapacity() {
        #expect(CacheCapacityPreset.small.diskCapacity == 20 * 1024 * 1024) // 20MB
        #expect(CacheCapacityPreset.medium.diskCapacity == 50 * 1024 * 1024) // 50MB
        #expect(CacheCapacityPreset.large.diskCapacity == 100 * 1024 * 1024) // 100MB
    }
    
    // MARK: - CacheUsage Tests
    
    @Test("CacheUsage는 메모리 사용률을 올바르게 계산한다")
    func cacheUsageCalculatesMemoryUsagePercentageCorrectly() {
        let usage = CacheUsage(
            memoryUsage: 5 * 1024 * 1024,         // 5MB
            diskUsage: 0,
            memoryCapacity: 10 * 1024 * 1024,     // 10MB
            diskCapacity: 50 * 1024 * 1024
        )
        
        #expect(usage.memoryUsagePercentage == 50.0)
    }
    
    @Test("CacheUsage는 디스크 사용률을 올바르게 계산한다")
    func cacheUsageCalculatesDiskUsagePercentageCorrectly() {
        let usage = CacheUsage(
            memoryUsage: 0,
            diskUsage: 25 * 1024 * 1024,          // 25MB
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024       // 100MB
        )
        
        #expect(usage.diskUsagePercentage == 25.0)
    }
    
    @Test("CacheUsage는 0 용량일 때 0%를 반환한다")
    func cacheUsageReturnsZeroPercentageWhenCapacityIsZero() {
        let usage = CacheUsage(
            memoryUsage: 5 * 1024 * 1024,
            diskUsage: 10 * 1024 * 1024,
            memoryCapacity: 0,
            diskCapacity: 0
        )
        
        #expect(usage.memoryUsagePercentage == 0.0)
        #expect(usage.diskUsagePercentage == 0.0)
    }
    
    @Test("CacheUsage.formattedMemoryUsage는 읽기 쉬운 형식을 반환한다")
    func cacheUsageFormattedMemoryUsageIsReadable() {
        let usage = CacheUsage(
            memoryUsage: 5 * 1024 * 1024,         // 5MB
            diskUsage: 0,
            memoryCapacity: 10 * 1024 * 1024,     // 10MB
            diskCapacity: 50 * 1024 * 1024
        )
        
        let formatted = usage.formattedMemoryUsage
        #expect(formatted.contains("MB"))
        #expect(formatted.contains("/"))
    }
    
    @Test("CacheUsage.formattedDiskUsage는 읽기 쉬운 형식을 반환한다")
    func cacheUsageFormattedDiskUsageIsReadable() {
        let usage = CacheUsage(
            memoryUsage: 0,
            diskUsage: 25 * 1024 * 1024,          // 25MB
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024       // 100MB
        )
        
        let formatted = usage.formattedDiskUsage
        #expect(formatted.contains("MB"))
        #expect(formatted.contains("/"))
    }
    
    // MARK: - NetworkConfigurationPreset Tests

    @Test("NetworkConfigurationPreset은 모든 프리셋을 제공한다")
    func networkConfigurationPresetProvidesAllPresets() {
        let presets = NetworkConfigurationPreset.allCases

        #expect(presets.count == 5)
        #expect(presets.contains(.development))
        #expect(presets.contains(.default))
        #expect(presets.contains(.stable))
        #expect(presets.contains(.fast))
        #expect(presets.contains(.test))
    }

    @Test("NetworkConfigurationPreset의 displayName은 명확하다")
    func networkConfigurationPresetDisplayNamesAreClear() {
        #expect(NetworkConfigurationPreset.development.displayName == "Development")
        #expect(NetworkConfigurationPreset.default.displayName == "Default")
        #expect(NetworkConfigurationPreset.stable.displayName == "Stable")
        #expect(NetworkConfigurationPreset.fast.displayName == "Fast")
        #expect(NetworkConfigurationPreset.test.displayName == "Test")
    }

    @Test("NetworkConfigurationPreset의 description은 상세 정보를 제공한다")
    func networkConfigurationPresetDescriptionsProvideDetails() {
        #expect(NetworkConfigurationPreset.development.description.contains("재시도"))
        #expect(NetworkConfigurationPreset.default.description.contains("일반"))
        #expect(NetworkConfigurationPreset.stable.description.contains("안정"))
        #expect(NetworkConfigurationPreset.fast.description.contains("빠른"))
        #expect(NetworkConfigurationPreset.test.description.contains("테스트"))
    }

    // MARK: - RetryPolicyPreset Tests

    @Test("RetryPolicyPreset은 모든 프리셋을 제공한다")
    func retryPolicyPresetProvidesAllPresets() {
        let presets = RetryPolicyPreset.allCases

        #expect(presets.count == 5)
        #expect(presets.contains(.standard))
        #expect(presets.contains(.quick))
        #expect(presets.contains(.patient))
        #expect(presets.contains(.none))
        #expect(presets.contains(.custom))
    }

    @Test("RetryPolicyPreset의 displayName은 명확하다")
    func retryPolicyPresetDisplayNamesAreClear() {
        #expect(RetryPolicyPreset.standard.displayName == "표준 (Standard)")
        #expect(RetryPolicyPreset.quick.displayName == "빠름 (Quick)")
        #expect(RetryPolicyPreset.patient.displayName == "느림 (Patient)")
        #expect(RetryPolicyPreset.none.displayName == "재시도 없음")
        #expect(RetryPolicyPreset.custom.displayName == "커스텀")
    }

    @Test("RetryPolicyPreset의 maxRetries는 올바른 값을 반환한다")
    func retryPolicyPresetReturnsCorrectMaxRetries() {
        #expect(RetryPolicyPreset.standard.maxRetries == 3)
        #expect(RetryPolicyPreset.quick.maxRetries == 5)
        #expect(RetryPolicyPreset.patient.maxRetries == 1)
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

    // MARK: - NetworkStatus Tests

    @Test("NetworkStatus는 연결 타입을 올바르게 표현한다")
    func networkStatusRepresentsConnectionTypeCorrectly() {
        #expect(NetworkStatus.connected(.wifi).displayName == "Connected")
        #expect(NetworkStatus.connected(.cellular).displayName == "Connected")
        #expect(NetworkStatus.disconnected.displayName == "Disconnected")
    }

    @Test("NetworkStatus는 연결 타입 설명을 제공한다")
    func networkStatusProvidesConnectionTypeDescription() {
        #expect(NetworkStatus.connected(.wifi).connectionTypeDescription == "Wi-Fi")
        #expect(NetworkStatus.connected(.cellular).connectionTypeDescription == "Cellular")
        #expect(NetworkStatus.connected(.ethernet).connectionTypeDescription == "Ethernet")
        #expect(NetworkStatus.disconnected.connectionTypeDescription == "None")
    }

    @Test("NetworkStatus의 isConnected는 올바른 값을 반환한다")
    func networkStatusIsConnectedReturnsCorrectValue() {
        #expect(NetworkStatus.connected(.wifi).isConnected == true)
        #expect(NetworkStatus.connected(.cellular).isConnected == true)
        #expect(NetworkStatus.disconnected.isConnected == false)
    }
}
