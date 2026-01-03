//
//  NetworkMonitor.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Combine
import Foundation
import Network

public protocol NetworkMonitoring: AnyObject, Sendable {
    var isConnected: Bool { get }
    var connectionType: NetworkMonitor.ConnectionType { get }
    var currentPath: NWPath? { get }
    var isExpensive: Bool { get }
    var isConstrained: Bool { get }

    func startMonitoring()
    func stopMonitoring()
}

/// 네트워크 연결 상태를 실시간으로 모니터링합니다.
public final class NetworkMonitor: ObservableObject, NetworkMonitoring, @unchecked Sendable {
    public static let shared = NetworkMonitor()

    public enum ConnectionType: Sendable {
        case wifi
        case cellular
        case ethernet
        case loopback
        case unknown

        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .loopback: return "Loopback"
            case .unknown: return "Unknown"
            }
        }
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.asyncnetwork.networkmonitor")

    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var connectionType: ConnectionType = .unknown
    @Published public private(set) var currentPath: NWPath?

    public var isExpensive: Bool {
        currentPath?.isExpensive ?? false
    }

    public var isConstrained: Bool {
        currentPath?.isConstrained ?? false
    }

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }

        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }

    private func handlePathUpdate(_ path: NWPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let wasConnected = self.isConnected
            let newIsConnected = path.status == .satisfied

            self.currentPath = path
            self.isConnected = newIsConnected
            self.connectionType = self.determineConnectionType(from: path)

            // 네트워크 상태 변경 알림
            if wasConnected != newIsConnected {
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: [
                        "isConnected": newIsConnected,
                        "connectionType": self.connectionType
                    ]
                )
            }
        }
    }

    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        }
        return .unknown
    }
}

public extension Notification.Name {
    static let networkStatusChanged = Notification.Name("com.asyncnetwork.networkStatusChanged")
}
