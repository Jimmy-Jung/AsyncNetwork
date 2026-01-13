//
//  NetworkMonitorIntegrationTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import AsyncViewModel
import Network
import Testing

/// NetworkMonitor 통합 테스트
@Suite("NetworkMonitor 통합")
@MainActor
struct NetworkMonitorIntegrationTests {
    // MARK: - ViewModel Integration Tests

    @Test("ViewModel이 NetworkMonitor의 초기 상태를 로드한다")
    func viewModelLoadsInitialNetworkMonitorState() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .wifi
        mockMonitor.isExpensive = false
        mockMonitor.isConstrained = false

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .connected(.wifi))
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == false)
    }

    @Test("ViewModel이 NetworkMonitor의 연결 해제 상태를 처리한다")
    func viewModelHandlesNetworkMonitorDisconnectedState() async throws {
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

    @Test("ViewModel이 NetworkMonitor의 Expensive 플래그를 처리한다")
    func viewModelHandlesNetworkMonitorExpensiveFlag() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .cellular
        mockMonitor.isExpensive = true
        mockMonitor.isConstrained = false

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .connected(.cellular))
        #expect(store.state.isExpensive == true)
        #expect(store.state.isConstrained == false)
    }

    @Test("ViewModel이 NetworkMonitor의 Constrained 플래그를 처리한다")
    func viewModelHandlesNetworkMonitorConstrainedFlag() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .wifi
        mockMonitor.isExpensive = false
        mockMonitor.isConstrained = true

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .connected(.wifi))
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == true)
    }

    @Test("ViewModel이 모든 연결 타입을 올바르게 처리한다", arguments: [
        NetworkMonitor.ConnectionType.wifi,
        NetworkMonitor.ConnectionType.cellular,
        NetworkMonitor.ConnectionType.ethernet,
        NetworkMonitor.ConnectionType.loopback,
        NetworkMonitor.ConnectionType.unknown
    ])
    func viewModelHandlesAllConnectionTypes(connectionType: NetworkMonitor.ConnectionType) async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = true
        mockMonitor.connectionType = connectionType

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .connected(connectionType))
    }

    @Test("viewDidDisappear 시 NetworkMonitor 구독이 취소된다")
    func viewDidDisappearCancelsNetworkMonitorSubscription() async throws {
        let mockMonitor = MockNetworkMonitor()
        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .connected(.wifi))

        store.send(.viewDidDisappear)
        try await store.waitForEffects()

        // Effect가 취소되었는지 확인 (추가 Action이 없어야 함)
        store.cleanup()
    }

    // MARK: - State Consistency Tests

    @Test("NetworkStatus와 연결 플래그가 일관성 있게 업데이트된다")
    func networkStatusAndFlagsUpdateConsistently() async throws {
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
        #expect(store.state.networkStatus.isConnected == true)
        #expect(store.state.isExpensive == true)
        #expect(store.state.isConstrained == true)
    }

    @Test("연결 해제 시 모든 플래그가 초기화된다")
    func disconnectedStateClearsAllFlags() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = false
        mockMonitor.isExpensive = false
        mockMonitor.isConstrained = false

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == .disconnected)
        #expect(store.state.networkStatus.isConnected == false)
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == false)
    }
}

// MARK: - Mock NetworkMonitor

/// NetworkMonitor의 Mock 구현
final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    var isConnected: Bool = true
    var connectionType: NetworkMonitor.ConnectionType = .wifi
    var currentPath: NWPath?
    var isExpensive: Bool = false
    var isConstrained: Bool = false

    func startMonitoring() {}
    func stopMonitoring() {}
}
