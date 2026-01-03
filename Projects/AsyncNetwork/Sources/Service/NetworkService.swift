//
//  NetworkService.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public struct NetworkService: Sendable {
    private let httpClient: any HTTPClientProtocol
    private let retryPolicy: RetryPolicy
    private let responseProcessor: any ResponseProcessing
    private let delayer: AsyncDelayer
    private let interceptors: [any RequestInterceptor]
    private let networkMonitor: (any NetworkMonitoring)?
    private let checkNetworkBeforeRequest: Bool

    public init(
        httpClient: any HTTPClientProtocol,
        retryPolicy: RetryPolicy,
        responseProcessor: any ResponseProcessing,
        interceptors: [any RequestInterceptor] = [],
        delayer: AsyncDelayer = SystemDelayer(),
        networkMonitor: (any NetworkMonitoring)? = NetworkMonitor.shared,
        checkNetworkBeforeRequest: Bool = true
    ) {
        self.httpClient = httpClient
        self.retryPolicy = retryPolicy
        self.responseProcessor = responseProcessor
        self.interceptors = interceptors
        self.delayer = delayer
        self.networkMonitor = networkMonitor
        self.checkNetworkBeforeRequest = checkNetworkBeforeRequest
    }

    public init(
        configuration: NetworkConfiguration = .default,
        plugins: [any RequestInterceptor]? = nil
    ) {
        let defaultPlugins: [any RequestInterceptor] = plugins ?? [
            ConsoleLoggingInterceptor(minimumLevel: .verbose)
        ]

        self.init(
            httpClient: HTTPClient(configuration: configuration),
            retryPolicy: RetryPolicy.default,
            responseProcessor: ResponseProcessor(),
            interceptors: defaultPlugins,
            delayer: SystemDelayer(),
            networkMonitor: NetworkMonitor.shared,
            checkNetworkBeforeRequest: true
        )
    }

    public var isNetworkAvailable: Bool {
        networkMonitor?.isConnected ?? true
    }

    public var connectionType: NetworkMonitor.ConnectionType {
        networkMonitor?.connectionType ?? .unknown
    }

    public func request<R: APIRequest, T: Decodable>(
        request: R,
        decodeType: T.Type
    ) async throws -> T {
        if checkNetworkBeforeRequest, !isNetworkAvailable {
            throw NetworkError.offline
        }

        let response = try await execute(request)
        return try responseProcessor.process(
            result: .success(response),
            decodeType: decodeType,
            request: request
        ).get()
    }

    public func request<R: APIRequest>(
        _ request: R
    ) async throws -> R.Response {
        try await self.request(request: request, decodeType: R.Response.self)
    }

    public func requestData<R: APIRequest>(
        _ request: R
    ) async throws -> Data {
        let response = try await execute(request)
        return try responseProcessor.validateAndExtractData(response, request: request)
    }

    public func requestRaw<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        try await execute(request)
    }

    private func execute<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        var urlRequest = try request.asURLRequest()
        var attempt = 1
        let maxAttempts = retryPolicy.configuration.maxRetries + 1

        while attempt <= maxAttempts {
            do {
                return try await executeWithInterceptors(
                    urlRequest: &urlRequest,
                    target: request
                )
            } catch {
                if attempt >= maxAttempts {
                    throw error
                }
                try await handleRetry(error: error, attempt: &attempt)
            }
        }

        throw NetworkError.unknown(
            NSError(
                domain: "AsyncNetwork",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected: exceeded max attempts without throwing"]
            )
        )
    }

    private func executeWithInterceptors<R: APIRequest>(
        urlRequest: inout URLRequest,
        target: R
    ) async throws -> HTTPResponse {
        for interceptor in interceptors {
            try await interceptor.prepare(&urlRequest, target: target)
        }

        for interceptor in interceptors {
            await interceptor.willSend(urlRequest, target: target)
        }

        let response = try await httpClient.request(urlRequest)

        for interceptor in interceptors {
            await interceptor.didReceive(response, target: target)
        }

        return response
    }

    private func handleRetry(error: Error, attempt: inout Int) async throws {
        let decision = retryPolicy.shouldRetry(error: error, attempt: attempt)
        switch decision {
        case let .retry(delay):
            try await delayer.sleep(seconds: delay)
            attempt += 1
        case .stop:
            throw error
        case .retryImmediately:
            attempt += 1
        }
    }
}
