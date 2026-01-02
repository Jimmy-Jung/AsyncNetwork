//
//  APIRequestTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - APIRequestTests

struct APIRequestTests {
    // MARK: - Test Models

    private struct RequestJSONBody: Codable, Sendable {
        let username: String
        let password: String
    }

    private struct SimpleRequest: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/users"
        var method: HTTPMethod = .get
    }

    private struct RequestWithHeaders: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/auth"
        var method: HTTPMethod = .post
        var headers: [String: String]? = [
            "Authorization": "Bearer token",
            "X-Custom": "value"
        ]
    }

    private struct RequestWithTimeout: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/slow"
        var method: HTTPMethod = .get
        var timeout: TimeInterval = 60.0
    }

    private struct RequestWithJSONBody: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/login"
        var method: HTTPMethod = .post

        @RequestBody var body: RequestJSONBody?

        init(body: RequestJSONBody) {
            self.body = body
        }
    }

    // MARK: - Default Values Tests

    @Test("APIRequest 기본 timeout 값")
    func defaultTimeoutValue() {
        // Given
        let request = SimpleRequest()

        // Then
        #expect(request.timeout == 30.0)
    }

    @Test("APIRequest 기본 headers 값은 nil")
    func defaultHeadersIsNil() {
        // Given
        let request = SimpleRequest()

        // Then
        #expect(request.headers == nil)
    }

    // MARK: - asURLRequest Tests

    @Test("asURLRequest - 기본 GET 요청")
    func asURLRequestBasicGet() throws {
        // Given
        let request = SimpleRequest()

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.url?.absoluteString == "https://api.example.com/users")
        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.timeoutInterval == 30.0)
    }

    @Test("asURLRequest - 헤더 포함")
    func asURLRequestWithHeaders() throws {
        // Given
        let request = RequestWithHeaders()

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom") == "value")
    }

    @Test("asURLRequest - 커스텀 timeout")
    func asURLRequestWithCustomTimeout() throws {
        // Given
        let request = RequestWithTimeout()

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.timeoutInterval == 60.0)
    }

    @Test("asURLRequest - JSON 본문 포함 (RequestBody PropertyWrapper)")
    func asURLRequestWithJSONBody() throws {
        // Given
        let body = RequestJSONBody(username: "user", password: "pass")
        let request = RequestWithJSONBody(body: body)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpBody != nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")

        // JSON 내용 검증
        struct DecodedBody: Decodable {
            let username: String
            let password: String
        }
        let decoded = try JSONDecoder().decode(DecodedBody.self, from: urlRequest.httpBody!)
        #expect(decoded.username == "user")
        #expect(decoded.password == "pass")
    }

    @Test("asURLRequest - 다양한 HTTP 메서드", arguments: [
        HTTPMethod.get,
        HTTPMethod.post,
        HTTPMethod.put,
        HTTPMethod.delete,
        HTTPMethod.patch
    ])
    func asURLRequestWithVariousMethods(method: HTTPMethod) throws {
        // Given
        struct MethodRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/test"
            var method: HTTPMethod
        }

        let request = MethodRequest(method: method)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpMethod == method.rawValue)
    }

    @Test("asURLRequest - path 슬래시 처리")
    func asURLRequestPathHandling() throws {
        // Given
        struct PathRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String
            var method: HTTPMethod = .get
        }

        let request = PathRequest(path: "/v1/users/123")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.url?.absoluteString == "https://api.example.com/v1/users/123")
    }

    @Test("asURLRequest - QueryParameter PropertyWrapper")
    func asURLRequestWithQueryParameters() throws {
        // Given
        struct QueryRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/search"
            var method: HTTPMethod = .get

            @QueryParameter var q: String?
            @QueryParameter var page: String?

            init(q: String, page: String) {
                self.q = q
                self.page = page
            }
        }

        let request = QueryRequest(q: "test", page: "1")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let urlString = urlRequest.url?.absoluteString ?? ""
        #expect(urlString.contains("q=test"))
        #expect(urlString.contains("page=1"))
    }
}
