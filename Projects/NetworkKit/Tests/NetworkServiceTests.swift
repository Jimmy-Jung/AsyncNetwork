//
//  NetworkServiceTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation
@testable import NetworkKit
import Testing

// MARK: - NetworkServiceTests

struct NetworkServiceTests {
    // MARK: - Test Models

    private struct TestUser: Codable, Equatable {
        let id: Int
        let name: String
    }

    private struct TestAPIRequest: APIRequest {
        var baseURL: URL = .init(string: "https://api.example.com")!
        var path: String
        var method: HTTPMethod = .get
        var task: HTTPTask = .requestPlain

        init(path: String) {
            self.path = path
        }
    }

    // MARK: - Tests

    @Test("성공적인 네트워크 요청 및 디코딩")
    func successfulRequestAndDecoding() async throws {
        // Given
        let path = "/users/success"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        // Mock Response Data
        let expectedUser = TestUser(id: 1, name: "John Doe")
        let responseData = try JSONEncoder().encode(expectedUser)

        MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: .none,
            configuration: .test,
            responseProcessor: ResponseProcessor()
        )

        // When
        let user = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user == expectedUser)
    }

    @Test("재시도 로직 동작 확인 (1회 실패 후 성공)")
    func retryLogicSuccessAfterFailure() async throws {
        // Given
        let path = "/users/retry"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let expectedUser = TestUser(id: 1, name: "Retry User")
        let responseData = try JSONEncoder().encode(expectedUser)

        // 상태를 관리하기 위해 actor나 lock이 필요하지만, 여기서는 단순화를 위해 nonisolated(unsafe) 사용
        // 실제로는 더 정교한 모킹 라이브러리를 사용하는 것이 좋음
        class RetryState {
            var attemptCount = 0
        }
        let state = RetryState()

        MockURLProtocol.register(path: path) { request in
            state.attemptCount += 1
            if state.attemptCount == 1 {
                throw URLError(.timedOut) // 재시도 가능한 에러
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let retryConfig = RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.01,
            maxDelay: 0.1
        )

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: retryConfig),
            configuration: .test,
            responseProcessor: ResponseProcessor(),
            delayer: SystemDelayer()
        )

        // When
        let user = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user == expectedUser)
        #expect(state.attemptCount == 2)
    }

    @Test("최대 재시도 횟수 초과 시 에러 반환")
    func failAfterMaxRetries() async throws {
        // Given
        let path = "/users/fail_max_retries"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        MockURLProtocol.register(path: path) { _ in
            throw URLError(.timedOut)
        }

        let retryConfig = RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.01,
            maxDelay: 0.1
        )

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: retryConfig),
            configuration: .test,
            responseProcessor: ResponseProcessor()
        )

        // When & Then
        await #expect(throws: URLError.self) {
            try await service.request(
                request: TestAPIRequest(path: path),
                decodeType: TestUser.self
            )
        }
    }

    @Test("인터셉터 동작 확인")
    func verifyRequestInterceptor() async throws {
        // Given
        let path = "/users/interceptor"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        struct TestInterceptor: RequestInterceptor {
            func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws {
                request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
            }
        }

        MockURLProtocol.register(path: path) { request in
            if request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                // swiftlint:disable:next force_try
                let data = try! JSONEncoder().encode(TestUser(id: 1, name: "Auth User"))
                return (response, data)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: .none,
            configuration: .test,
            responseProcessor: ResponseProcessor(),
            interceptors: [TestInterceptor()]
        )

        // When
        let user = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user.name == "Auth User")
    }
}
