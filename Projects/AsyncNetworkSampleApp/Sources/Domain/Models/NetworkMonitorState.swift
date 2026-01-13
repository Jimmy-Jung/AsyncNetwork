//
//  NetworkMonitorState.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import Foundation

// MARK: - ConnectionStatus

/// 네트워크 연결 상태
enum ConnectionStatus: String, Equatable, Sendable {
    case connected
    case disconnected
    case unknown

    var displayName: String {
        switch self {
        case .connected: return "연결됨"
        case .disconnected: return "연결 끊김"
        case .unknown: return "알 수 없음"
        }
    }

    var icon: String {
        switch self {
        case .connected: return "wifi"
        case .disconnected: return "wifi.slash"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .connected: return "green"
        case .disconnected: return "red"
        case .unknown: return "gray"
        }
    }
}

// MARK: - NetworkPathInfo

/// 네트워크 경로 정보
struct NetworkPathInfo: Equatable, Sendable {
    let isExpensive: Bool
    let isConstrained: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool
    let supportsDNS: Bool

    var summary: String {
        var parts: [String] = []
        if isExpensive { parts.append("고비용") }
        if isConstrained { parts.append("제한됨") }
        if supportsIPv4 { parts.append("IPv4") }
        if supportsIPv6 { parts.append("IPv6") }
        if supportsDNS { parts.append("DNS") }
        return parts.isEmpty ? "정보 없음" : parts.joined(separator: ", ")
    }
}

// MARK: - NetworkStatusHistory

/// 네트워크 상태 히스토리
struct NetworkStatusHistory: Identifiable, Equatable, Sendable {
    let id: UUID
    let status: ConnectionStatus
    let timestamp: Date
    let pathInfo: NetworkPathInfo?

    init(
        status: ConnectionStatus,
        timestamp: Date = Date(),
        pathInfo: NetworkPathInfo? = nil
    ) {
        id = UUID()
        self.status = status
        self.timestamp = timestamp
        self.pathInfo = pathInfo
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
