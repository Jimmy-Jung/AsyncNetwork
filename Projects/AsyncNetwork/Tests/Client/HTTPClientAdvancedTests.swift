//
//  HTTPClientAdvancedTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - HTTPClientAdvancedTests

/// HTTPClient의 고급 기능 및 엣지 케이스 테스트
struct HTTPClientAdvancedTests {
    // MARK: - Test Models

    private struct TestAPIRequest: APIRequest {
        var baseURLString: String = "https://example.com"
        var path: String
        var method: HTTPMethod = .get
        var headers: [String: String]?

        init(path: String = "/test", method: HTTPMethod = .get, headers: [String: String]? = nil) {
            self.path = path
            self.method = method
            self.headers = headers
        }
    }

    private struct RequestWithBody: APIRequest {
        var baseURLString: String = "https://example.com"
        var path: String
        var method: HTTPMethod = .post

        @RequestBody var body: TestPayload?

        init(path: String, body: TestPayload) {
            self.path = path
            self.body = body
        }
    }

    private struct TestPayload: Codable, Sendable {
        let name: String
        let value: Int
    }

    // MARK: - Edge Cases

    @Test("빈 응답 데이터 처리")
    func handleEmptyResponseData() async throws {
        // Given
        let path = "/empty"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 200)
        #expect(response.data.isEmpty)
    }

    @Test("큰 응답 데이터 처리 (1MB)")
    func handleLargeResponseData() async throws {
        // Given
        let path = "/large"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let largeData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, largeData)
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 200)
        #expect(response.data.count == 1024 * 1024)
    }

    @Test("특수 문자가 포함된 경로 처리")
    func handleSpecialCharactersInPath() async throws {
        // Given
        let path = "/users/john-doe_123"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("success".utf8))
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 200)
    }

    @Test("중첩된 경로 처리")
    func handleNestedPath() async throws {
        // Given
        let path = "/api/v1/users/123/posts/456/comments"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("nested".utf8))
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 200)
    }

    // MARK: - HTTP Methods

    @Test("POST 요청 처리", arguments: [HTTPMethod.post, .put, .patch, .delete])
    func handleDifferentHTTPMethods(method: HTTPMethod) async throws {
        // Given
        let path = "/test-\(method.rawValue)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            #expect(request.httpMethod == method.rawValue)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("success".utf8))
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path, method: method))

        // Then
        #expect(response.statusCode == 200)
    }

    // MARK: - Headers

    @Test("커스텀 헤더 전송 확인")
    func verifyCustomHeaders() async throws {
        // Given
        let path = "/headers"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let customHeaders = [
            "X-Custom-Header": "CustomValue",
            "User-Agent": "TestClient/1.0",
            "Accept-Language": "ko-KR",
        ]

        await MockURLProtocol.register(path: path) { request in
            // 헤더 검증
            #expect(request.value(forHTTPHeaderField: "X-Custom-Header") == "CustomValue")
            #expect(request.value(forHTTPHeaderField: "User-Agent") == "TestClient/1.0")
            #expect(request.value(forHTTPHeaderField: "Accept-Language") == "ko-KR")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path, headers: customHeaders))

        // Then
        #expect(response.statusCode == 200)
    }

    @Test("응답 헤더 파싱 확인")
    func verifyResponseHeaders() async throws {
        // Given
        let path = "/response-headers"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let expectedHeaders = [
            "Content-Type": "application/json",
            "X-Request-ID": "12345",
            "Cache-Control": "no-cache",
        ]

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: expectedHeaders
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 200)
        if let headerFields = response.response?.allHeaderFields as? [String: String] {
            #expect(headerFields["Content-Type"] == "application/json")
            #expect(headerFields["X-Request-ID"] == "12345")
            #expect(headerFields["Cache-Control"] == "no-cache")
        }
    }

    // MARK: - Status Codes

    @Test("다양한 성공 상태 코드 처리", arguments: [200, 201, 202, 204])
    func handleSuccessStatusCodes(statusCode: Int) async throws {
        // Given
        let path = "/status-\(statusCode)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == statusCode)
    }

    @Test("리다이렉션 상태 코드 처리", arguments: [301, 302, 303, 307, 308])
    func handleRedirectionStatusCodes(statusCode: Int) async throws {
        // Given
        let path = "/redirect-\(statusCode)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Location": "https://example.com/new-location"]
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == statusCode)
    }

    @Test("클라이언트 에러 상태 코드 처리", arguments: [400, 401, 403, 404, 422, 429])
    func handleClientErrorStatusCodes(statusCode: Int) async throws {
        // Given
        let path = "/error-\(statusCode)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == statusCode)
    }

    @Test("서버 에러 상태 코드 처리", arguments: [500, 502, 503, 504])
    func handleServerErrorStatusCodes(statusCode: Int) async throws {
        // Given
        let path = "/server-error-\(statusCode)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == statusCode)
    }

    // MARK: - Concurrency

    @Test("동시 요청 처리 (10개)")
    func handleConcurrentRequests() async throws {
        // Given
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let requestCount = 10

        // 모든 경로에 대한 Mock 등록
        for index in 0 ..< requestCount {
            let path = "/concurrent-\(index)"
            await MockURLProtocol.register(path: path) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data("result-\(index)".utf8))
            }
        }

        // When - 동시에 여러 요청 실행
        let results = try await withThrowingTaskGroup(of: (Int, HTTPResponse).self) { group in
            for index in 0 ..< requestCount {
                group.addTask {
                    let path = "/concurrent-\(index)"
                    let response = try await client.request(TestAPIRequest(path: path))
                    return (index, response)
                }
            }

            var responses: [(Int, HTTPResponse)] = []
            for try await result in group {
                responses.append(result)
            }
            return responses
        }

        // Then
        #expect(results.count == requestCount)
        for (index, response) in results {
            #expect(response.statusCode == 200)
            let expectedData = Data("result-\(index)".utf8)
            #expect(response.data == expectedData)
        }
    }

    // MARK: - Error Handling

    @Test("다양한 URLError 처리", arguments: [
        URLError.Code.timedOut,
        .cannotConnectToHost,
        .networkConnectionLost,
        .dnsLookupFailed,
        .notConnectedToInternet,
    ])
    func handleDifferentURLErrors(errorCode: URLError.Code) async {
        // Given
        let path = "/error-\(errorCode.rawValue)"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let expectedError = URLError(errorCode)

        await MockURLProtocol.register(path: path) { _ in
            throw expectedError
        }

        // When & Then
        await #expect(throws: URLError.self) {
            try await client.request(TestAPIRequest(path: path))
        }
    }

    // MARK: - Request Body

    @Test("JSON 요청 바디 전송 확인")
    func verifyJSONRequestBody() async throws {
        // Given
        let path = "/post-json"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let payload = TestPayload(name: "test", value: 42)

        await MockURLProtocol.register(path: path) { request in
            // 요청 바디 검증
            if let body = request.httpBody, !body.isEmpty {
                let decodedPayload = try? JSONDecoder().decode(TestPayload.self, from: body)
                #expect(decodedPayload?.name == "test")
                #expect(decodedPayload?.value == 42)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(RequestWithBody(path: path, body: payload))

        // Then
        #expect(response.statusCode == 201)
    }

    @Test("빈 요청 바디 전송")
    func sendEmptyRequestBody() async throws {
        // Given
        let path = "/post-empty"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            // httpBody가 없거나 빈 데이터여야 함
            if let body = request.httpBody {
                #expect(body.isEmpty)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path, method: .post))

        // Then
        #expect(response.statusCode == 200)
    }
}
