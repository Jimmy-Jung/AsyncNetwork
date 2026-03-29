//
//  DemoMocks.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
import Foundation

struct DemoAuthInterceptor: RequestInterceptor {
    let token: String

    func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

actor StaticDemoHTTPClient: HTTPClientProtocol {
    private let responseData: Data
    private let statusCode: Int

    init(responseData: Data, statusCode: Int = 200) {
        self.responseData = responseData
        self.statusCode = statusCode
    }

    func request(_ request: any APIRequest) async throws -> HTTPResponse {
        try await self.request(request.asURLRequest())
    }

    func request(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        let response = HTTPURLResponse(
            url: urlRequest.url ?? URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )

        return HTTPResponse(
            statusCode: statusCode,
            data: responseData,
            request: urlRequest,
            response: response
        )
    }
}

actor FlakyDemoHTTPClient: HTTPClientProtocol {
    private var remainingFailures: Int
    private let responseData: Data
    private(set) var attemptHistory: [String] = []

    init(failuresBeforeSuccess: Int, responseData: Data) {
        remainingFailures = failuresBeforeSuccess
        self.responseData = responseData
    }

    func request(_ request: any APIRequest) async throws -> HTTPResponse {
        try await self.request(request.asURLRequest())
    }

    func request(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        let attemptNumber = attemptHistory.count + 1

        if remainingFailures > 0 {
            remainingFailures -= 1
            attemptHistory.append("Attempt \(attemptNumber): timedOut")
            throw URLError(.timedOut)
        }

        attemptHistory.append("Attempt \(attemptNumber): success")
        let response = HTTPURLResponse(
            url: urlRequest.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )

        return HTTPResponse(
            statusCode: 200,
            data: responseData,
            request: urlRequest,
            response: response
        )
    }
}

final class ExampleMockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    private var callbacks: [@Sendable (NetworkStatus) -> Void] = []

    var isConnected: Bool
    var connectionType: ConnectionType
    var isExpensive: Bool
    var isConstrained: Bool

    var status: NetworkStatus {
        isConnected ? .connected(connectionType) : .disconnected
    }

    init(
        isConnected: Bool,
        connectionType: ConnectionType = .unknown,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    func startMonitoring() {}
    func stopMonitoring() {}

    func onStatusChange(_ callback: @escaping @Sendable (NetworkStatus) -> Void) {
        callbacks.append(callback)
    }

    func update(
        isConnected: Bool,
        connectionType: ConnectionType,
        isExpensive: Bool,
        isConstrained: Bool
    ) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained

        let currentStatus = status
        callbacks.forEach { $0(currentStatus) }
    }
}
