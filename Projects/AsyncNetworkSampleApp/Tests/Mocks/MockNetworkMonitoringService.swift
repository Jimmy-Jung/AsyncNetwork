//
//  MockNetworkMonitoringService.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/13.
//

import AsyncNetwork
import Foundation
@testable import AsyncNetworkSampleApp

/// 테스트용 NetworkMonitoringService Mock
/// ObservableObject로 DefaultNetworkMonitoringService와 동일한 인터페이스 제공
@MainActor
public final class MockNetworkMonitoringService: NetworkMonitoringService, ObservableObject {
    // MARK: - Published Properties
    
    @Published public var isConnected: Bool
    @Published public var connectionType: ConnectionType
    @Published public var status: NetworkStatus
    @Published public var isExpensive: Bool
    @Published public var isConstrained: Bool
    
    // MARK: - Computed Properties
    
    public var summary: String {
        """
        Connection: \(isConnected ? "✅" : "❌")
        Type: \(connectionType.description)
        Expensive: \(isExpensive ? "⚠️" : "✅")
        Constrained: \(isConstrained ? "⚠️" : "✅")
        """
    }
    
    // MARK: - Initialization
    
    public init(
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
    
    // MARK: - Test Helpers
    
    /// 오프라인 상태로 시뮬레이션
    public func simulateOffline() {
        isConnected = false
        connectionType = .unknown
        status = .disconnected
        isExpensive = false
        isConstrained = false
    }
    
    /// 온라인 상태로 시뮬레이션
    public func simulateOnline(
        type: ConnectionType = .wifi,
        expensive: Bool = false,
        constrained: Bool = false
    ) {
        isConnected = true
        connectionType = type
        status = .connected(type)
        isExpensive = expensive
        isConstrained = constrained
    }
    
    /// Wi-Fi 연결 시뮬레이션
    public func simulateWiFi() {
        simulateOnline(type: .wifi, expensive: false, constrained: false)
    }
    
    /// 셀룰러 연결 시뮬레이션 (비용 많이 듦)
    public func simulateCellular(constrained: Bool = false) {
        simulateOnline(type: .cellular, expensive: true, constrained: constrained)
    }
    
    /// 제한된 연결 시뮬레이션 (Low Data Mode)
    public func simulateConstrained() {
        simulateOnline(type: .wifi, expensive: false, constrained: true)
    }
}
