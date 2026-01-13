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

        #expect(viewModel.state.retryPolicyPreset == .patient)
        #expect(viewModel.state.loggingLevel == .verbose)
        #expect(viewModel.state.networkStatus == .connected(.wifi))
        #expect(viewModel.state.isExpensive == false)
        #expect(viewModel.state.isConstrained == false)
        #expect(viewModel.state.etagCacheUsage.currentCount == 0)
        #expect(viewModel.state.etagCacheUsage.capacity == 1000)
    }

    // MARK: - ETag Cache Tests
    
    @Test("refreshETagCacheUsage 시 ETag 캐시 사용량이 업데이트된다")
    func refreshETagCacheUsageUpdatesUsage() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)
        
        store.send(.refreshETagCacheUsageTapped)
        
        // waitForEffects()가 Effect가 완료될 때까지 대기
        try await store.waitForEffects()
        
        // 추가 대기: Effect가 완료되고 상태 업데이트가 반영될 시간
        try await Task.sleep(for: .milliseconds(100))
        
        // Effect가 완료되면 ETag 캐시 사용량이 로드되고, isRefreshingETagCache가 false로 변경됨
        #expect(store.state.etagCacheUsage.capacity == 1000)
        #expect(store.state.isRefreshingETagCache == false)
    }
    
    @Test("clearETagCache 시 ETag 캐시가 비워진다")
    func clearETagCacheRemovesAllCachedETags() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)
        
        store.send(.clearETagCacheTapped)
        try await store.waitForEffects()

        // clearETagCache 후 사용량이 0으로 초기화되어야 함
        #expect(store.state.etagCacheUsage.currentCount == 0)
    }

    @Test("invalidateAllETags 시 모든 ETag가 무효화된다")
    func invalidateAllETagsInvalidatesCache() async throws {
        let viewModel = SettingsViewModel(networkMonitor: MockNetworkMonitor())
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.invalidateAllETagsTapped)
        try await store.waitForEffects()

        // invalidateAllETags 후 사용량이 0으로 초기화되어야 함
        #expect(store.state.etagCacheUsage.currentCount == 0)
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

        #expect(store.state.retryPolicyPreset == .patient)
        #expect(store.state.loggingLevel == .verbose)
    }
}
