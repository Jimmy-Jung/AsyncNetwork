//
//  NetworkMonitoringService.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/13.
//

import AsyncNetwork
import Combine
import Foundation

// MARK: - NetworkMonitoringService Protocol

/// 네트워크 모니터링 서비스 프로토콜
///
/// ## 책임
/// - Presentation 레이어에서 네트워크 상태를 관찰하기 위한 서비스
/// - NetworkMonitor의 상태를 ObservableObject로 래핑하여 SwiftUI와 통합
///
/// ## 설계 원칙
/// - Presentation/Services: UI 레이어를 지원하는 인프라 서비스
/// - NetworkMonitor는 Infrastructure 레이어에서 주입받음
/// - 비즈니스 로직이 아닌 상태 관찰 어댑터 역할
///
/// ## 사용 예시
///
/// ### SwiftUI에서 사용
/// ```swift
/// struct NetworkStatusView: View {
///     @ObservedObject var networkMonitoring: DefaultNetworkMonitoringService
///
///     var body: some View {
///         if networkMonitoring.isConnected {
///             Text("Connected: \(networkMonitoring.connectionType.description)")
///         } else {
///             Text("Offline")
///         }
///     }
/// }
/// ```
///
/// ### 테스트에서 Mock 사용
/// ```swift
/// let mockService = MockNetworkMonitoringService(isConnected: false)
/// let view = MyView(networkMonitoring: mockService)
/// ```
@MainActor
public protocol NetworkMonitoringService: AnyObject, ObservableObject {
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
    
    /// 네트워크 상태 요약 정보
    var summary: String { get }
}

// MARK: - DefaultNetworkMonitoringService

/// 네트워크 모니터링 서비스 기본 구현
///
/// ## 책임
/// - NetworkMonitor로부터 상태 변경 콜백 수신
/// - @Published 프로퍼티로 UI 레이어에 상태 변경 알림
/// - ObservableObject 구현으로 SwiftUI와 통합
///
/// ## 설계 원칙
/// - Presentation/Services: NetworkMonitor를 의존성으로 주입받음
/// - Presentation 레이어에서 @ObservedObject로 사용
/// - 상태는 읽기 전용으로 노출 (private(set))
///
/// ## 사용 예시
///
/// ### SwiftUI View에서 사용
/// ```swift
/// struct MyView: View {
///     @ObservedObject var networkMonitoring: DefaultNetworkMonitoringService
///
///     var body: some View {
///         if networkMonitoring.isConnected {
///             Text("Online")
///         } else {
///             Text("Offline")
///         }
///     }
/// }
/// ```
///
/// ### AppDependency에서 초기화
/// ```swift
/// let networkMonitor = NetworkMonitor.shared
/// let networkMonitoringService = DefaultNetworkMonitoringService(monitor: networkMonitor)
/// ```
@MainActor
public final class DefaultNetworkMonitoringService: NetworkMonitoringService, ObservableObject {
    // MARK: - Published Properties
    
    @Published public private(set) var isConnected: Bool
    @Published public private(set) var connectionType: ConnectionType
    @Published public private(set) var status: NetworkStatus
    @Published public private(set) var isExpensive: Bool
    @Published public private(set) var isConstrained: Bool
    
    // MARK: - Private Properties
    
    private let monitor: any NetworkMonitoring
    
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
    
    public init(monitor: any NetworkMonitoring) {
        self.monitor = monitor
        
        // 초기 상태 설정
        self.isConnected = monitor.isConnected
        self.connectionType = monitor.connectionType
        self.status = monitor.status
        self.isExpensive = monitor.isExpensive
        self.isConstrained = monitor.isConstrained
        
        // 상태 변경 콜백 등록
        monitor.onStatusChange { [weak self] newStatus in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.status = newStatus
                self.isConnected = monitor.isConnected
                self.connectionType = monitor.connectionType
                self.isExpensive = monitor.isExpensive
                self.isConstrained = monitor.isConstrained
            }
        }
    }
}
