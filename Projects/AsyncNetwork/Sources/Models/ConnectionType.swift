//
//  ConnectionType.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/13.
//

import Foundation

/// 네트워크 연결 타입
public enum ConnectionType: Sendable, Equatable {
    case wifi
    case cellular
    case ethernet
    case loopback
    case unknown

    public var description: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .unknown: return "Unknown"
        }
    }

    public var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .loopback: return "arrow.triangle.2.circlepath"
        case .unknown: return "network"
        }
    }
}
