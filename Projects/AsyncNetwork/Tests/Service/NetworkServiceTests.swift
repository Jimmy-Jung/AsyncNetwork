//
//  NetworkServiceTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - Test Models

private struct TestUser: Codable, Equatable {
    let id: Int
    let name: String
}

private struct TestAPIRequest: APIRequest {
    typealias Response = EmptyResponse

    var baseURLString: String = "https://api.example.com"
    var path: String
    var method: HTTPMethod = .get

    init(path: String) {
        self.path = path
    }
}

private struct TypedTestAPIRequest: APIRequest {
    typealias Response = TestUser

    var baseURLString: String = "https://api.example.com"
    var path: String
    var method: HTTPMethod = .get

    init(path: String) {
        self.path = path
    }
}

private struct LogoutRequest: APIRequest {
    typealias Response = EmptyResponse

    var baseURLString: String = "https://api.example.com"
    var path: String = "/auth/logout"
    var method: HTTPMethod = .post
}

// MARK: - NetworkServiceTests

struct NetworkServiceTests {
    // MARK: - Tests

    @Test("성공적인 네트워크 요청 및 디코딩")
    func successfulRequestAndDecoding() async throws { // Given
        let path = "/users/success"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        // Mock Response Data
        let expectedUser = TestUser(id: 1, name: "John Doe")
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { request in
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
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
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

        // ✅ Sendable한 상태 관리
        actor RetryState {
            private(set) var attemptCount = 0
            func incrementAndGet() -> Int {
                attemptCount += 1
                return attemptCount
            }
        }
        let state = RetryState()

        await MockURLProtocol.register(path: path) { [state] request in
            let semaphore = DispatchSemaphore(value: 0)
            var currentAttempt = 0
            Task {
                currentAttempt = await state.incrementAndGet()
                semaphore.signal()
            }
            semaphore.wait()

            if currentAttempt == 1 {
                throw URLError(.timedOut)
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
        let finalCount = await state.getCount()
        #expect(finalCount == 2)
    }

    @Test("최대 재시도 횟수 초과 시 에러 반환")
    func failAfterMaxRetries() async throws { // Given
        let path = "/users/fail_max_retries"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { _ in
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
    func verifyRequestInterceptor() async throws { // Given
        let path = "/users/interceptor"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        struct TestInterceptor: RequestInterceptor {
            func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
                request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
            }
        }

        await MockURLProtocol.register(path: path) { request in
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
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
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

    @Test("associatedtype Response를 사용한 타입 추론 요청")
    func requestWithAssociatedTypeResponse() async throws { // Given
        let path = "/users/typed"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let expectedUser = TestUser(id: 42, name: "Typed User")
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { request in
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
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When - 타입을 명시하지 않고 요청 (associatedtype Response 사용)
        let user = try await service.request(TypedTestAPIRequest(path: path))

        // Then
        #expect(user == expectedUser)
        #expect(user.id == 42)
        #expect(user.name == "Typed User")
    }

    @Test("associatedtype Response와 명시적 타입 지정 비교")
    func compareAssociatedTypeVsExplicitType() async throws { // Given
        let path = "/users/compare"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let expectedUser = TestUser(id: 100, name: "Compare User")
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { request in
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
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When - 두 가지 방식으로 요청
        let user1 = try await service.request(TypedTestAPIRequest(path: path))
        let user2 = try await service.request(
            request: TypedTestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then - 두 결과가 동일해야 함
        #expect(user1 == user2)
        #expect(user1 == expectedUser)
    }

    @Test("빈 응답 EmptyResponse 처리")
    func requestWithEmptyResponse() async throws { // Given
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        await MockURLProtocol.register(path: "/auth/logout") { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When
        let emptyResponse = try await service.request(LogoutRequest())

        // Then
        _ = emptyResponse // 사용되었음을 표시
    }
}
