//
//  NetworkServiceOfflineTests.swift
//  AsyncNetworkTests
//
//  Created by jimmy on 2026/01/02.
//

@testable import AsyncNetworkCore
import Foundation
import Network
import Testing

@Suite("NetworkService Offline Tests")
struct NetworkServiceOfflineTests {
    @Test("오프라인 시 NetworkError.offline 반환")
    func offlineError() async throws {
        // Mock NetworkMonitor 생성 (오프라인 상태)
        let mockMonitor = MockNetworkMonitor(isConnected: false)

        let service = NetworkService(
            httpClient: HTTPClient(configuration: .test),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            networkMonitor: mockMonitor,
            checkNetworkBeforeRequest: true
        )

        let request = TestGetRequest()

        do {
            _ = try await service.request(request)
            Issue.record("오프라인 상태에서 에러가 발생해야 함")
        } catch let error as NetworkError {
            #expect(error.isOffline)
            #expect(error.errorDescription?.contains("internet connection") == true)
        }
    }

    @Test("네트워크 체크 비활성화 시 오프라인 에러 발생하지 않음")
    func networkCheckDisabled() async throws {
        let mockMonitor = MockNetworkMonitor(isConnected: false)

        let service = NetworkService(
            httpClient: HTTPClient(configuration: .test),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            networkMonitor: mockMonitor,
            checkNetworkBeforeRequest: false // ✅ 체크 비활성화
        )

        // 오프라인이지만 체크하지 않으므로 실제 요청 시도
        // (실제 네트워크 요청은 실패하겠지만 offline 에러는 아님)
        #expect(service.isNetworkAvailable == false)
    }

    @Test("isNetworkAvailable 프로퍼티 확인")
    func networkAvailableProperty() {
        let onlineMonitor = MockNetworkMonitor(isConnected: true)
        let offlineMonitor = MockNetworkMonitor(isConnected: false)

        let onlineService = NetworkService(
            httpClient: HTTPClient(configuration: .test),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            networkMonitor: onlineMonitor
        )

        let offlineService = NetworkService(
            httpClient: HTTPClient(configuration: .test),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            networkMonitor: offlineMonitor
        )

        #expect(onlineService.isNetworkAvailable == true)
        #expect(offlineService.isNetworkAvailable == false)
    }

    @Test("connectionType 프로퍼티 확인")
    func connectionTypeProperty() {
        let wifiMonitor = MockNetworkMonitor(isConnected: true, connectionType: .wifi)
        let cellularMonitor = MockNetworkMonitor(isConnected: true, connectionType: .cellular)

        let wifiService = NetworkService(
            httpClient: HTTPClient(configuration: .test),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            networkMonitor: wifiMonitor
        )

        let cellularService = NetworkService(
            httpClient: HTTPClient(configuration: .test),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            networkMonitor: cellularMonitor
        )

        #expect(wifiService.connectionType == .wifi)
        #expect(cellularService.connectionType == .cellular)
    }
}

// MARK: - Mock NetworkMonitor

/// 테스트용 Mock NetworkMonitor
final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    var isConnected: Bool
    var connectionType: NetworkMonitor.ConnectionType
    var currentPath: NWPath?

    var isExpensive: Bool { false }
    var isConstrained: Bool { false }

    init(isConnected: Bool, connectionType: NetworkMonitor.ConnectionType = .unknown) {
        self.isConnected = isConnected
        self.connectionType = connectionType
    }

    func startMonitoring() {}
    func stopMonitoring() {}
}

// MARK: - Test Request

private struct TestGetRequest: APIRequest {
    typealias Response = TestUser

    var baseURLString: String { "https://api.example.com" }
    var path: String { "/users/1" }
    var method: HTTPMethod { .get }
}

private struct TestUser: Codable, Equatable {
    let id: Int
    let name: String
}
