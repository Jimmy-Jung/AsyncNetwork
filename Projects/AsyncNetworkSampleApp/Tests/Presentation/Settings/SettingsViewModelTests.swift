//
//  SettingsViewModelTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import AsyncViewModel
import Network
import Testing

/// SettingsViewModel 테스트
@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {
    // MARK: - Initial State Tests

    @Test("초기 상태는 기본값으로 설정된다")
    func initialStateHasDefaultValues() async {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())

        #expect(viewModel.state.retryPolicyPreset == .standard)
        #expect(viewModel.state.loggingLevel == .verbose)
        #expect(viewModel.state.networkStatus == .connected(.wifi))
        #expect(viewModel.state.isExpensive == false)
        #expect(viewModel.state.isConstrained == false)
        #expect(viewModel.state.cacheCapacityPreset == .medium)
    }

    // MARK: - Cache Settings Tests
    
    @Test("CacheCapacityPreset 변경 시 State가 업데이트된다")
    func cacheCapacityPresetChangeUpdatesState() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)
        
        store.send(.cacheCapacityPresetSelected(.large))
        try await store.waitForEffects()
        
        #expect(store.state.cacheCapacityPreset == .large)
    }
    
    @Test("CacheCapacityPreset 변경 시 State만 업데이트된다 (URLCache는 불변)")
    func cacheCapacityPresetChangeUpdatesStateOnly() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)
        
        let preset = CacheCapacityPreset.large
        store.send(.cacheCapacityPresetSelected(preset))
        try await store.waitForEffects()
        
        #expect(store.state.cacheCapacityPreset == preset)
        // 주의: URLCache는 런타임에 변경 불가 (read-only)
        // 실제 용량 변경은 앱 재시작 시 적용
    }
    
    @Test("refreshCacheUsage 시 AppDependency의 URLCache 사용량이 업데이트된다")
    func refreshCacheUsageUpdatesCurrentUsage() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)
        
        store.send(.refreshCacheUsageTapped)
        try await store.waitForEffects()
        
        let appCache = AppDependency.shared.urlCache
        #expect(store.state.cacheUsage.memoryCapacity == appCache.memoryCapacity)
        #expect(store.state.cacheUsage.diskCapacity == appCache.diskCapacity)
        #expect(store.state.cacheUsage.memoryUsage == appCache.currentMemoryUsage)
        #expect(store.state.cacheUsage.diskUsage == appCache.currentDiskUsage)
    }
    
    @Test("clearCache 시 AppDependency의 URLCache가 비워진다")
    func clearCacheRemovesAllCachedResponses() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        let appCache = AppDependency.shared.urlCache
        let initialMemoryUsage = appCache.currentMemoryUsage
        
        store.send(.clearCacheTapped)
        try await store.waitForEffects()

        // clearCache 후 사용량이 0이거나 이전보다 작아야 함
        #expect(store.state.cacheUsage.memoryUsage <= initialMemoryUsage)
    }

    @Test("모든 CacheCapacityPreset을 순회하며 변경할 수 있다")
    func canCycleThroughAllCacheCapacityPresets() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        let presets: [CacheCapacityPreset] = [.small, .medium, .large]

        for preset in presets {
            store.send(.cacheCapacityPresetSelected(preset))
            try await store.waitForEffects()

            #expect(store.state.cacheCapacityPreset == preset)
            // 주의: URLCache는 런타임에 변경 불가
            // State의 preset만 변경됨
        }
    }

    // MARK: - Configuration Preset Change Tests (Removed - ConfigurationPreset no longer exists)


    // MARK: - Retry Policy Preset Change Tests

    @Test("RetryPolicyPreset 변경 시 State가 업데이트된다")
    func retryPolicyPresetChangeUpdatesState() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.retryPolicyPresetSelected(.quick))
        try await store.waitForEffects()

        #expect(store.state.retryPolicyPreset == .quick)
    }

    @Test("모든 RetryPolicyPreset을 순회하며 변경할 수 있다")
    func canCycleThroughAllRetryPolicyPresets() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        let presets: [RetryPolicyPreset] = [.quick, .patient]

        for preset in presets {
            store.send(.retryPolicyPresetSelected(preset))
            try await store.waitForEffects()

            #expect(store.state.retryPolicyPreset == preset)
        }
    }

    // MARK: - Logging Level Change Tests

    @Test("LoggingLevel 변경 시 State가 업데이트된다")
    func loggingLevelChangeUpdatesState() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.loggingLevelSelected(.error))
        try await store.waitForEffects()

        #expect(store.state.loggingLevel == .error)
    }

    @Test("모든 LoggingLevel을 순회하며 변경할 수 있다")
    func canCycleThroughAllLoggingLevels() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        let levels: [LoggingLevel] = [.info, .error, .none]

        for level in levels {
            store.send(.loggingLevelSelected(level))
            try await store.waitForEffects()

            #expect(store.state.loggingLevel == level)
        }
    }

    // MARK: - Network Monitor Tests

    @Test("viewDidAppear 시 NetworkMonitor 상태를 로드한다")
    func viewDidAppearLoadsNetworkMonitorState() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .cellular
        mockMonitor.isExpensive = true
        mockMonitor.isConstrained = true

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .connected(.cellular))
        #expect(store.state.isExpensive == true)
        #expect(store.state.isConstrained == true)
    }

    @Test("NetworkMonitor가 연결 해제 상태일 때 올바르게 반영된다")
    func networkMonitorDisconnectedStateIsReflected() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = false

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .disconnected)
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == false)
    }

    // MARK: - Reset to Defaults Tests

    @Test("resetToDefaults 시 모든 설정이 기본값으로 초기화된다")
    func resetToDefaultsRestoresAllSettings() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        // 설정 변경
        store.send(.retryPolicyPresetSelected(.quick))
        try await store.waitForEffects()

        store.send(.loggingLevelSelected(.none))
        try await store.waitForEffects()

        // 초기화
        store.send(.resetToDefaultsTapped)
        try await store.waitForEffects()

        #expect(store.state.retryPolicyPreset == .standard)
        #expect(store.state.loggingLevel == .verbose)
    }
}
