//
//  NetworkMonitor.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation
import Network

// MARK: - NetworkStatus

/// 네트워크 상태
public enum NetworkStatus: Equatable, Sendable {
    case connected(ConnectionType)
    case disconnected

    public var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        }
    }

    public var connectionTypeDescription: String {
        switch self {
        case let .connected(type):
            return type.description
        case .disconnected:
            return "None"
        }
    }

    public var isConnected: Bool {
        switch self {
        case .connected: return true
        case .disconnected: return false
        }
    }
}

// MARK: - NetworkMonitoring Protocol

/// 네트워크 모니터링을 위한 프로토콜
///
/// ## 설계 철학
/// - **최소한의 인터페이스**: 동기 상태 getter만 정의
/// - **순수 인프라 레벨**: NetworkService에서 네트워크 연결 상태 확인 용도
/// - **관찰 기능 분리**: UI 레이어에서 사용하려면 NetworkMonitoringUseCase 사용
///
/// ## 사용 예시
///
/// ### NetworkService에서 사용
/// ```swift
/// let service = NetworkService(
///     networkMonitor: NetworkMonitor.shared,
///     checkNetworkBeforeRequest: true
/// )
/// ```
///
/// ### UI 레이어에서 상태 관찰 (UseCase 사용)
/// ```swift
/// let useCase = DefaultNetworkMonitoringUseCase(monitor: NetworkMonitor.shared)
/// // useCase는 ObservableObject이므로 SwiftUI에서 @ObservedObject로 사용 가능
/// ```
public protocol NetworkMonitoring: AnyObject, Sendable {
    // MARK: - Synchronous State (Required)
    
    /// 현재 네트워크 연결 여부
    var isConnected: Bool { get }
    
    /// 현재 연결 타입 (Wi-Fi, Cellular 등)
    var connectionType: ConnectionType { get }
    
    /// 현재 네트워크 상태
    var status: NetworkStatus { get }
    
    /// 비용이 많이 드는 연결인지 여부 (셀룰러 등)
    var isExpensive: Bool { get }
    
    /// 제한된 연결인지 여부 (Low Data Mode 등)
    var isConstrained: Bool { get }
    
    // MARK: - Lifecycle Methods
    
    /// 모니터링 시작
    func startMonitoring()
    
    /// 모니터링 중지
    func stopMonitoring()
    
    // MARK: - Callback Registration
    
    /// 네트워크 상태 변경 콜백 등록
    /// - Parameter callback: 상태 변경 시 호출될 콜백
    func onStatusChange(_ callback: @escaping @Sendable (NetworkStatus) -> Void)
}

// MARK: - NetworkMonitoring + Default Implementation

public extension NetworkMonitoring {
    /// 네트워크 상태 요약 정보
    var summary: String {
        """
        Connection: \(isConnected ? "✅" : "❌")
        Type: \(connectionType.description)
        Expensive: \(isExpensive ? "⚠️" : "✅")
        Constrained: \(isConstrained ? "⚠️" : "✅")
        """
    }
}

/// 네트워크 연결 상태를 실시간으로 모니터링합니다.
///
/// ## 특징
/// - `NWPathMonitor` 기반 Apple 표준 구현
/// - 순수 인프라 레벨: 네트워크 상태 감지만 담당
/// - 콜백 기반 상태 알림
///
/// ## 사용 예시
///
/// ### NetworkService에서 직접 사용
/// ```swift
/// let monitor = NetworkMonitor.shared
/// if !monitor.isConnected {
///     throw NetworkError.offline
/// }
/// ```
///
/// ### UI 레이어에서 UseCase를 통한 관찰
/// ```swift
/// let useCase = DefaultNetworkMonitoringUseCase(monitor: NetworkMonitor.shared)
/// // useCase는 ObservableObject이므로 SwiftUI에서 @ObservedObject로 사용
/// ```
public final class NetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    public static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.asyncnetwork.networkmonitor")
    
    // MARK: - State (Thread-safe via DispatchQueue)
    
    private var _isConnected: Bool = true
    private var _connectionType: ConnectionType = .unknown
    private var _status: NetworkStatus = .connected(.unknown)
    private var _currentPath: NWPath?
    
    // MARK: - Callbacks
    
    private var statusChangeCallbacks: [@Sendable (NetworkStatus) -> Void] = []

    // MARK: - Protocol Implementation (Computed Properties)
    
    public var isConnected: Bool {
        queue.sync { _isConnected }
    }
    
    public var connectionType: ConnectionType {
        queue.sync { _connectionType }
    }
    
    public var status: NetworkStatus {
        queue.sync { _status }
    }

    public var isExpensive: Bool {
        queue.sync { _currentPath?.isExpensive ?? false }
    }

    public var isConstrained: Bool {
        queue.sync { _currentPath?.isConstrained ?? false }
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
    
    public func onStatusChange(_ callback: @escaping @Sendable (NetworkStatus) -> Void) {
        queue.async { [weak self] in
            self?.statusChangeCallbacks.append(callback)
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let newIsConnected = path.status == .satisfied

            self._currentPath = path
            self._isConnected = newIsConnected
            self._connectionType = self.determineConnectionType(from: path)

            // NetworkStatus 업데이트
            self._status = newIsConnected
                ? .connected(self._connectionType)
                : .disconnected
            
            // 콜백 호출
            let currentStatus = self._status
            DispatchQueue.main.async {
                self.statusChangeCallbacks.forEach { $0(currentStatus) }
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
