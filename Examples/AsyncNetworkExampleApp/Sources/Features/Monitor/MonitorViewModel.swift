//
//  MonitorViewModel.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
import Foundation
import SwiftUI

struct MonitorSnapshot: Equatable, Sendable {
    let statusText: String
    let connectionType: String
    let isExpensive: Bool
    let isConstrained: Bool
}

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published private(set) var liveSnapshot: MonitorSnapshot
    @Published private(set) var comparisonState: DemoLoadState = .idle

    private let monitor: any NetworkMonitoring

    init(monitor: any NetworkMonitoring = NetworkMonitor.shared) {
        self.monitor = monitor
        liveSnapshot = Self.makeSnapshot(from: monitor)
    }

    func startMonitoring() {
        liveSnapshot = Self.makeSnapshot(from: monitor)
        monitor.onStatusChange { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.liveSnapshot = Self.makeSnapshot(from: self.monitor)
            }
        }
    }

    func compareOfflineGuard() async {
        comparisonState = .loading

        let request = GetPostsRequest(userId: 1, limit: 2)
        let mockMonitor = ExampleMockNetworkMonitor(isConnected: false, connectionType: .wifi)
        let client = StaticDemoHTTPClient(responseData: DemoFixtures.samplePostsData)

        let guardedService = NetworkService(
            httpClient: client,
            retryPolicy: RetryPolicy(),
            responseProcessor: ResponseProcessor(),
            interceptors: [],
            networkMonitor: mockMonitor,
            checkNetworkBeforeRequest: true
        )

        let bypassService = NetworkService(
            httpClient: client,
            retryPolicy: RetryPolicy(),
            responseProcessor: ResponseProcessor(),
            interceptors: [],
            networkMonitor: mockMonitor,
            checkNetworkBeforeRequest: false
        )

        do {
            var lines: [String] = []

            do {
                let _: [DemoPost] = try await guardedService.request(request)
                lines.append("guarded service: unexpected success")
            } catch {
                lines.append("guarded service: \(error.localizedDescription)")
            }

            let bypassPosts: [DemoPost] = try await bypassService.request(request)
            lines.append("bypass service: \(bypassPosts.count) posts loaded")

            let urlRequest = try request.asURLRequest()
            comparisonState = .success(
                DemoRunOutput(
                    method: urlRequest.httpMethod ?? "GET",
                    requestURL: urlRequest.url?.absoluteString ?? "unknown",
                    headers: [],
                    metadataLines: lines,
                    responsePreview: DemoJSONFormatter.prettyString(from: bypassPosts)
                )
            )
        } catch {
            comparisonState = .failure(error.localizedDescription)
        }
    }

    private static func makeSnapshot(from monitor: any NetworkMonitoring) -> MonitorSnapshot {
        MonitorSnapshot(
            statusText: monitor.status.displayName,
            connectionType: monitor.connectionType.description,
            isExpensive: monitor.isExpensive,
            isConstrained: monitor.isConstrained
        )
    }
}
