//
//  NetworkService.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - NetworkService

/// 클린 아키텍처 기반 네트워크 서비스
///
/// **단일 책임:**
/// - 네트워크 컴포넌트들의 조율
/// - 재시도 로직 관리
/// - 타입 안전한 API 제공
public struct NetworkService: Sendable {
    private let httpClient: HTTPClient
    private let retryPolicy: RetryPolicy
    private let configuration: NetworkConfiguration

    // Processors
    private let responseProcessor: any ResponseProcessing
    private let dataResponseProcessor: any DataResponseProcessing

    private let delayer: AsyncDelayer
    private let interceptors: [any RequestInterceptor]

    public init(
        httpClient: HTTPClient,
        retryPolicy: RetryPolicy,
        configuration: NetworkConfiguration,
        responseProcessor: any ResponseProcessing,
        dataResponseProcessor: any DataResponseProcessing = DataResponseProcessor(),
        interceptors: [any RequestInterceptor] = [],
        delayer: AsyncDelayer = SystemDelayer()
    ) {
        self.httpClient = httpClient
        self.retryPolicy = retryPolicy
        self.configuration = configuration
        self.responseProcessor = responseProcessor
        self.dataResponseProcessor = dataResponseProcessor
        self.interceptors = interceptors
        self.delayer = delayer
    }

    /// 네트워크 요청 실행 (Decodable)
    /// - Parameters:
    ///   - request: 실행할 API 요청
    ///   - decodeType: 디코딩할 타입
    /// - Returns: 디코딩된 응답 객체
    public func request<R: APIRequest, T: Decodable>(
        request: R,
        decodeType: T.Type
    ) async throws -> T {
        // 1. 초기 URLRequest 변환
        let initialURLRequest = try request.asURLRequest()

        var attempt = 1
        while true {
            do {
                // 2. 인터셉터 적용
                let adaptedRequest = try await applyInterceptors(to: initialURLRequest)

                // 3. 요청 실행
                let response = try await httpClient.request(adaptedRequest)

                // 4. 응답 처리 및 디코딩
                return try responseProcessor.process(
                    result: .success(response),
                    decodeType: decodeType,
                    request: request
                ).get()
            } catch {
                try await handleRetry(error: error, attempt: &attempt)
            }
        }
    }

    /// 네트워크 요청 실행 (Data 반환)
    /// - Parameter request: 실행할 API 요청
    /// - Returns: 응답 데이터 (Data)
    public func requestData<R: APIRequest>(
        _ request: R
    ) async throws -> Data {
        let initialURLRequest = try request.asURLRequest()

        var attempt = 1
        while true {
            do {
                let adaptedRequest = try await applyInterceptors(to: initialURLRequest)
                let response = try await httpClient.request(adaptedRequest)

                // Data 응답 처리
                return try dataResponseProcessor.process(
                    result: .success(response),
                    request: request
                ).get()

            } catch {
                try await handleRetry(error: error, attempt: &attempt)
            }
        }
    }

    /// 네트워크 요청 실행 (전체 응답 반환)
    /// - Parameter request: 실행할 API 요청
    /// - Returns: HTTPResponse 객체 (상태 코드, 헤더, 데이터 포함)
    public func requestRaw<R: APIRequest>(
        _ request: R
    ) async throws -> HTTPResponse {
        let initialURLRequest = try request.asURLRequest()

        var attempt = 1
        while true {
            do {
                let adaptedRequest = try await applyInterceptors(to: initialURLRequest)
                return try await httpClient.request(adaptedRequest)
            } catch {
                try await handleRetry(error: error, attempt: &attempt)
            }
        }
    }

    // MARK: - Private Helpers

    private func applyInterceptors(to request: URLRequest) async throws -> URLRequest {
        var finalRequest = request
        for interceptor in interceptors {
            finalRequest = try await interceptor.adapt(finalRequest)
        }
        return finalRequest
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
