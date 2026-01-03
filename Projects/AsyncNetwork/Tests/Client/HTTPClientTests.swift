//
//  HTTPClientTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - HTTPClientTests

struct HTTPClientTests {
    // MARK: - Test Models

    private struct TestAPIRequest: APIRequest {
        var baseURLString: String = "https://example.com"
        var path: String
        var method: HTTPMethod = .get
        var headers: [String: String]?

        init(path: String = "/test") {
            self.path = path
        }
    }

    // MARK: - Tests

    @Test("성공적인 GET 요청 처리")
    func successfulGetRequest() async throws {
        // Given
        let path = "/success_get"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let expectedData = Data("success".utf8)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedData)
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 200)
        #expect(response.data == expectedData)
    }

    @Test("404 에러 처리")
    func handle404Error() async throws {
        // Given
        let path = "/not_found"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        await MockURLProtocol.register(path: path) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When
        let response = try await client.request(TestAPIRequest(path: path))

        // Then
        #expect(response.statusCode == 404)
    }

    @Test("네트워크 에러 발생 시 예외 던짐")
    func handleNetworkError() async {
        // Given
        let path = "/network_error"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = HTTPClient(session: session)

        let networkError = URLError(.notConnectedToInternet)

        await MockURLProtocol.register(path: path) { _ in
            throw networkError
        }

        // When & Then
        await #expect(throws: URLError.self) {
            try await client.request(TestAPIRequest(path: path))
        }
    }
}
