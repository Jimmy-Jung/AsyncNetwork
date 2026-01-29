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

// MARK: - MockNetworkMonitor (테스트용)

/// 테스트용 NetworkMonitoring Mock
private final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    var isConnected: Bool = true
    var connectionType: ConnectionType = .wifi
    var status: NetworkStatus = .connected(.wifi)
    var isExpensive: Bool = false
    var isConstrained: Bool = false
    
    private var callbacks: [@Sendable (NetworkStatus) -> Void] = []
    
    init(
        isConnected: Bool = true,
        connectionType: ConnectionType = .wifi,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.status = isConnected ? .connected(connectionType) : .disconnected
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }
    
    func startMonitoring() {}
    func stopMonitoring() {}
    
    func onStatusChange(_ callback: @escaping @Sendable (NetworkStatus) -> Void) {
        callbacks.append(callback)
    }
    
    func simulateStatusChange(_ status: NetworkStatus) {
        self.status = status
        callbacks.forEach { $0(status) }
    }
}

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

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.connected(.wifi))
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == false)
    }

    @Test("ViewModel이 NetworkMonitor의 연결 해제 상태를 처리한다")
    func viewModelHandlesNetworkMonitorDisconnectedState() async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = false

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.disconnected)
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

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.connected(.cellular))
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

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.connected(.wifi))
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == true)
    }

    @Test("ViewModel이 모든 연결 타입을 올바르게 처리한다", arguments: [
        ConnectionType.wifi,
        ConnectionType.cellular,
        ConnectionType.ethernet,
        ConnectionType.loopback,
        ConnectionType.unknown
    ])
    func viewModelHandlesAllConnectionTypes(connectionType: ConnectionType) async throws {
        let mockMonitor = MockNetworkMonitor()
        mockMonitor.isConnected = true
        mockMonitor.connectionType = connectionType

        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.connected(connectionType))
    }

    @Test("viewDidDisappear 시 NetworkMonitor 구독이 취소된다")
    func viewDidDisappearCancelsNetworkMonitorSubscription() async throws {
        let mockMonitor = MockNetworkMonitor()
        let viewModel = SettingsViewModel(networkMonitor: mockMonitor)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.connected(.wifi))

        store.send(SettingsViewModel.Input.viewDidDisappear)
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

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.connected(.cellular))
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

        store.send(SettingsViewModel.Input.viewDidAppear)
        try await store.waitForEffects()

        #expect(store.state.networkStatus == NetworkStatus.disconnected)
        #expect(store.state.networkStatus.isConnected == false)
        #expect(store.state.isExpensive == false)
        #expect(store.state.isConstrained == false)
    }
}
