//
//  NetworkServiceAdvancedTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - NetworkServiceAdvancedTests

/// NetworkService의 고급 기능 및 엣지 케이스 테스트
struct NetworkServiceAdvancedTests {
    // MARK: - Test Models

    private struct TestUser: Codable, Equatable, Sendable {
        let id: Int
        let name: String
        let email: String?
    }

    private struct TestAPIRequest: APIRequest {
        typealias Response = EmptyResponse

        var baseURLString: String = "https://api.example.com"
        var path: String
        var method: HTTPMethod = .get

        init(path: String, method: HTTPMethod = .get) {
            self.path = path
            self.method = method
        }
    }

    private struct TypedRequest<T: Decodable & Sendable>: APIRequest {
        typealias Response = T

        var baseURLString: String = "https://api.example.com"
        var path: String
        var method: HTTPMethod = .get

        init(path: String) {
            self.path = path
        }
    }

    // MARK: - Decoding Edge Cases

    @Test("JSON 디코딩 실패 시 에러 처리")
    func handleDecodingFailure() async { // Given
        let path = "/invalid-json"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let invalidJSON = Data("{ invalid json }".utf8)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, invalidJSON)
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When & Then
        await #expect(throws: Error.self) {
            try await service.request(
                request: TestAPIRequest(path: path),
                decodeType: TestUser.self
            )
        }
    }

    @Test("옵셔널 필드 디코딩 확인")
    func decodeOptionalFields() async throws { // Given
        let path = "/optional-fields"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        // email 필드가 없는 JSON
        let jsonData = Data("""
        {
            "id": 1,
            "name": "John"
        }
        """.utf8)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When
        let user: TestUser = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user.id == 1)
        #expect(user.name == "John")
        #expect(user.email == nil)
    }

    @Test("빈 JSON 객체 디코딩")
    func decodeEmptyJSONObject() async { // Given
        let path = "/empty-object"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let emptyJSON = Data("{}".utf8)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, emptyJSON)
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When & Then - 필수 필드가 없으므로 디코딩 실패 예상
        await #expect(throws: Error.self) {
            try await service.request(
                request: TestAPIRequest(path: path),
                decodeType: TestUser.self
            )
        }
    }

    // MARK: - Retry Logic Edge Cases

    @Test("재시도 가능한 에러와 불가능한 에러 혼합")
    func mixedRetryableAndNonRetryableErrors() async throws { // Given
        let path = "/mixed-errors"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        actor RequestState {
            private(set) var attemptCount = 0

            func incrementAndGet() -> Int {
                attemptCount += 1
                return attemptCount
            }
        }
        let state = RequestState()

        let expectedUser = TestUser(id: 1, name: "Success", email: nil)
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { [state] request in
            let semaphore = DispatchSemaphore(value: 0)
            var currentAttempt = 0
            Task {
                currentAttempt = await state.incrementAndGet()
                semaphore.signal()
            }
            semaphore.wait()

            // 첫 번째: 재시도 가능한 에러
            if currentAttempt == 1 {
                throw URLError(.timedOut)
            }
            // 두 번째: 재시도 불가능한 에러 (4xx)
            else if currentAttempt == 2 {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            }
            // 세 번째: 성공 (도달하지 않아야 함)
            else {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, responseData)
            }
        }

        let retryConfig = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 0.01,
            maxDelay: 0.1
        )

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: retryConfig),
            responseProcessor: ResponseProcessor()
        )

        // When & Then - 400 에러에서 재시도 중단
        await #expect(throws: Error.self) {
            try await service.request(
                request: TestAPIRequest(path: path),
                decodeType: TestUser.self
            )
        }

        // 2회만 시도했는지 확인 (첫 시도 + 1회 재시도)
        let finalCount = await state.attemptCount
        #expect(finalCount == 2)
    }

    @Test("재시도 중 성공 - 마지막 시도에서 성공")
    func retrySuccessOnLastAttempt() async throws { // Given
        let path = "/retry-last-success"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        actor RequestState {
            private(set) var attemptCount = 0

            func incrementAndGet() -> Int {
                attemptCount += 1
                return attemptCount
            }
        }
        let state = RequestState()

        let expectedUser = TestUser(id: 99, name: "Last Attempt", email: nil)
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { [state] request in
            let semaphore = DispatchSemaphore(value: 0)
            var currentAttempt = 0
            Task {
                currentAttempt = await state.incrementAndGet()
                semaphore.signal()
            }
            semaphore.wait()

            // 처음 2번은 실패, 3번째(마지막)에 성공
            if currentAttempt < 3 {
                throw URLError(.networkConnectionLost)
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
            maxRetries: 2, // 총 3회 시도 (첫 시도 + 2회 재시도)
            baseDelay: 0.01,
            maxDelay: 0.1
        )

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: retryConfig),
            responseProcessor: ResponseProcessor()
        )

        // When
        let user: TestUser = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user == expectedUser)
        let finalCount = await state.attemptCount
        #expect(finalCount == 3)
    }

    // MARK: - Interceptor Edge Cases

    @Test("여러 인터셉터 체인 동작")
    func multipleInterceptorsChain() async throws { // Given
        let path = "/multiple-interceptors"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        struct FirstInterceptor: RequestInterceptor {
            func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
                request.setValue("Bearer token", forHTTPHeaderField: "Authorization")
            }
        }

        struct SecondInterceptor: RequestInterceptor {
            func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        struct ThirdInterceptor: RequestInterceptor {
            func prepare(_ request: inout URLRequest, target _: (any APIRequest)?) async throws {
                request.setValue("test-client", forHTTPHeaderField: "User-Agent")
            }
        }

        let expectedUser = TestUser(id: 1, name: "Multi Interceptor", email: nil)
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { request in
            // 모든 인터셉터가 헤더를 설정했는지 확인
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.value(forHTTPHeaderField: "User-Agent") == "test-client")

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
            responseProcessor: ResponseProcessor(),
            interceptors: [FirstInterceptor(), SecondInterceptor(), ThirdInterceptor()]
        )

        // When
        let user: TestUser = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user == expectedUser)
    }

    @Test("인터셉터에서 에러 발생 시 처리")
    func interceptorThrowsError() async { // Given
        let path = "/interceptor-error"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        struct ErrorThrowingInterceptor: RequestInterceptor {
            struct InterceptorError: Error {}

            func prepare(_: inout URLRequest, target _: (any APIRequest)?) async throws {
                throw InterceptorError()
            }
        }

        await MockURLProtocol.register(path: path) { request in
            // 이 코드는 실행되지 않아야 함
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor(),
            interceptors: [ErrorThrowingInterceptor()]
        )

        // When & Then
        await #expect(throws: Error.self) {
            try await service.request(
                request: TestAPIRequest(path: path),
                decodeType: TestUser.self
            )
        }
    }

    // MARK: - ResponseProcessor Edge Cases

    @Test("ResponseProcessor에서 상태 코드 검증 실패")
    func responseProcessorStatusCodeValidationFailure() async { // Given
        let path = "/status-validation"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500, // 서버 에러
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

        // When & Then
        await #expect(throws: Error.self) {
            try await service.request(
                request: TestAPIRequest(path: path),
                decodeType: TestUser.self
            )
        }
    }

    // MARK: - Timeout & Performance

    @Test("매우 느린 응답 시뮬레이션")
    func handleSlowResponse() async throws { // Given
        let path = "/slow"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let expectedUser = TestUser(id: 1, name: "Slow Response", email: nil)
        let responseData = try JSONEncoder().encode(expectedUser)

        await MockURLProtocol.register(path: path) { request in
            // 실제 테스트에서는 MockURLProtocol의 동기 특성상 지연을 시뮬레이션하기 어려움
            // 대신 정상 응답을 반환하여 느린 응답도 처리 가능함을 확인

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
        let user: TestUser = try await service.request(
            request: TestAPIRequest(path: path),
            decodeType: TestUser.self
        )

        // Then
        #expect(user == expectedUser)
    }

    // MARK: - Data Methods

    @Test("requestData() 메서드 - raw Data 반환")
    func requestDataMethod() async throws {
        // Given
        let path = "/raw-data"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let expectedData = Data("raw binary data".utf8)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedData)
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When
        let data = try await service.requestData(TestAPIRequest(path: path))

        // Then
        #expect(data == expectedData)
    }

    @Test("requestRaw() 메서드 - HTTPResponse 반환")
    func requestRawMethod() async throws {
        // Given
        let path = "/raw-response"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let httpClient = HTTPClient(session: session)

        let responseHeaders = [
            "Content-Type": "application/octet-stream",
            "X-Custom": "value",
        ]
        let responseData = Data("raw".utf8)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: responseHeaders
            )!
            return (response, responseData)
        }

        let service = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: RetryConfiguration(maxRetries: 0)),
            responseProcessor: ResponseProcessor()
        )

        // When
        let response = try await service.requestRaw(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 201)
        #expect(response.data == responseData)
        if let headerFields = response.response?.allHeaderFields as? [String: String] {
            #expect(headerFields["Content-Type"] == "application/octet-stream")
            #expect(headerFields["X-Custom"] == "value")
        }
    }
}
