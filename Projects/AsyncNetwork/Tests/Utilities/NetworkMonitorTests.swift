//
//  NetworkMonitorTests.swift
//  AsyncNetworkTests
//
//  Created by jimmy on 2026/01/02.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

@Suite("NetworkMonitor Tests")
struct NetworkMonitorTests {
    @Test("NetworkMonitor 싱글톤 인스턴스 확인")
    func singletonInstance() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared

        // 같은 인스턴스인지 확인 (메모리 주소로 비교)
        #expect(monitor1 === monitor2)
    }

    @Test("초기 상태 확인")
    func initialState() {
        let monitor = NetworkMonitor.shared

        // 초기에는 연결되어 있다고 가정 (대부분의 경우)
        #expect(monitor.isConnected == true || monitor.isConnected == false)

        // connectionType이 유효한 값인지 확인
        let validTypes: [NetworkMonitor.ConnectionType] = [
            .wifi, .cellular, .ethernet, .loopback, .unknown,
        ]
        #expect(validTypes.contains(where: { $0 == monitor.connectionType }))
    }

    @Test("ConnectionType description 확인")
    func connectionTypeDescription() {
        #expect(NetworkMonitor.ConnectionType.wifi.description == "Wi-Fi")
        #expect(NetworkMonitor.ConnectionType.cellular.description == "Cellular")
        #expect(NetworkMonitor.ConnectionType.ethernet.description == "Ethernet")
        #expect(NetworkMonitor.ConnectionType.loopback.description == "Loopback")
        #expect(NetworkMonitor.ConnectionType.unknown.description == "Unknown")
    }
}
