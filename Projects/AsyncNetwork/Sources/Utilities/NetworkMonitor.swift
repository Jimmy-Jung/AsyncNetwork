//
//  NetworkMonitor.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/02.
//

import Combine
import Foundation
import Network

/// 네트워크 모니터 프로토콜 (테스트용 Mock 지원)
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
///
/// 이 클래스는 `NWPathMonitor`를 사용하여 네트워크 상태 변경을 감지하고
/// Combine의 `@Published`를 통해 변경사항을 방출합니다.
///
/// ## 사용 예시
///
/// ```swift
/// // SwiftUI에서 사용
/// struct ContentView: View {
///     @StateObject private var monitor = NetworkMonitor.shared
///
///     var body: some View {
///         Text(monitor.isConnected ? "온라인" : "오프라인")
///     }
/// }
///
/// // Combine으로 구독
/// NetworkMonitor.shared.$isConnected
///     .sink { isConnected in
///         print("Network status: \(isConnected)")
///     }
/// ```
public final class NetworkMonitor: ObservableObject, NetworkMonitoring, @unchecked Sendable {
    // MARK: - Singleton

    /// 공유 인스턴스
    public static let shared = NetworkMonitor()

    // MARK: - Types

    /// 네트워크 연결 타입
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

    // MARK: - Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.asyncnetwork.networkmonitor")

    /// 현재 네트워크 연결 여부
    @Published public private(set) var isConnected: Bool = true

    /// 현재 네트워크 연결 타입
    @Published public private(set) var connectionType: ConnectionType = .unknown

    /// 현재 네트워크 경로 정보
    @Published public private(set) var currentPath: NWPath?

    /// 네트워크가 비용이 발생하는 연결인지 (예: Cellular 로밍)
    public var isExpensive: Bool {
        currentPath?.isExpensive ?? false
    }

    /// 네트워크가 제한된 연결인지 (예: 데이터 절약 모드)
    public var isConstrained: Bool {
        currentPath?.isConstrained ?? false
    }

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// 네트워크 모니터링을 시작합니다.
    ///
    /// - Note: 싱글톤 인스턴스는 자동으로 모니터링을 시작합니다.
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }

        monitor.start(queue: queue)
    }

    /// 네트워크 모니터링을 중지합니다.
    ///
    /// - Note: 배터리를 절약하기 위해 백그라운드에서는 중지하는 것이 좋습니다.
    public func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Private Methods

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

// MARK: - Notification Names

public extension Notification.Name {
    /// 네트워크 상태가 변경되었을 때 발송되는 알림
    ///
    /// - userInfo:
    ///   - "isConnected": Bool - 현재 연결 상태
    ///   - "connectionType": NetworkMonitor.ConnectionType - 연결 타입
    static let networkStatusChanged = Notification.Name("com.asyncnetwork.networkStatusChanged")
}
