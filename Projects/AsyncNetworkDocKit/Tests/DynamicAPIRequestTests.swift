//
//  DynamicAPIRequestTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/02.
//

import AsyncNetworkCore
@testable import AsyncNetworkDocKit
import Foundation
import Testing

@Suite("DynamicAPIRequest Tests")
struct DynamicAPIRequestTests {
    @Test("baseURLString이 올바르게 설정된다")
    func baseURLStringIsCorrectlySet() {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get
        )

        #expect(request.baseURLString == "https://api.example.com")
    }

    @Test("path가 올바르게 설정된다")
    func pathIsCorrectlySet() {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users/123",
            method: .get
        )

        #expect(request.path == "/users/123")
    }

    @Test("HTTPMethod가 올바르게 설정된다", arguments: [
        HTTPMethod.get,
        HTTPMethod.post,
        HTTPMethod.put,
        HTTPMethod.delete,
        HTTPMethod.patch
    ])
    func httpMethodIsCorrectlySet(method: HTTPMethod) {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: method
        )

        #expect(request.method == method)
    }

    @Test("헤더가 올바르게 설정된다")
    func headersAreCorrectlySet() {
        let headers = ["Authorization": "Bearer token123", "Content-Type": "application/json"]
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get,
            headers: headers
        )

        #expect(request.headers == headers)
    }

    @Test("헤더가 nil일 때 올바르게 처리된다")
    func nilHeadersAreHandledCorrectly() {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get,
            headers: nil
        )

        #expect(request.headers == nil)
    }

    @Test("timeout이 기본값 30으로 설정된다")
    func timeoutDefaultsTo30Seconds() {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get
        )

        #expect(request.timeout == 30)
    }

    @Test("query parameters만 있을 때 URL에 올바르게 추가된다")
    func queryParametersAreAddedToURL() throws {
        let queryParams = ["page": "1", "limit": "10"]
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get,
            queryParameters: queryParams
        )

        let urlRequest = try request.asURLRequest()
        let urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems ?? []

        #expect(queryItems.contains(where: { $0.name == "page" && $0.value == "1" }))
        #expect(queryItems.contains(where: { $0.name == "limit" && $0.value == "10" }))
    }

    @Test("빈 query parameters일 때 URL에 query string이 없다")
    func emptyQueryParametersDoesNotAddQueryString() throws {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get,
            queryParameters: [:]
        )

        let urlRequest = try request.asURLRequest()
        let urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)

        #expect(urlComponents?.queryItems == nil || urlComponents?.queryItems?.isEmpty == true)
    }

    @Test("body가 있을 때 httpBody에 올바르게 설정된다")
    func bodyDataIsSetInHTTPBody() throws {
        let bodyData = "{\"name\": \"John\"}".data(using: .utf8)!
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .post,
            body: bodyData
        )

        let urlRequest = try request.asURLRequest()
        #expect(urlRequest.httpBody == bodyData)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("body와 query parameters가 모두 있을 때 둘 다 올바르게 설정된다")
    func bodyAndQueryParametersAreBothSet() throws {
        let bodyData = "{\"name\": \"John\"}".data(using: .utf8)!
        let queryParams = ["page": "1"]
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .post,
            queryParameters: queryParams,
            body: bodyData
        )

        let urlRequest = try request.asURLRequest()

        // Body 검증
        #expect(urlRequest.httpBody == bodyData)

        // Query parameters 검증
        let urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems ?? []
        #expect(queryItems.contains(where: { $0.name == "page" && $0.value == "1" }))
    }

    @Test("body와 query parameters가 없을 때 기본 URLRequest가 생성된다")
    func plainRequestIsCreatedWhenNoBodyOrQuery() throws {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get
        )

        let urlRequest = try request.asURLRequest()

        #expect(urlRequest.httpBody == nil)
        let urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        #expect(urlComponents?.queryItems == nil || urlComponents?.queryItems?.isEmpty == true)
    }

    @Test("parseResponse는 원본 Data를 반환한다")
    func parseResponseReturnsOriginalData() throws {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get
        )

        let testData = "Test Response".data(using: .utf8)!
        let url = URL(string: "https://api.example.com/users")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = try request.parseResponse(data: testData, response: response)
        #expect(result == testData)
    }

    @Test("복잡한 JSON body를 가진 요청 생성")
    func complexJSONBodyRequest() throws {
        let jsonObject: [String: Any] = [
            "title": "Test Post",
            "userId": 1,
            "isPublished": true,
            "tags": ["swift", "testing"]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: jsonObject)

        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/posts",
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: bodyData
        )

        #expect(request.method == .post)
        #expect(request.headers?["Content-Type"] == "application/json")

        let urlRequest = try request.asURLRequest()
        #expect(urlRequest.httpBody == bodyData)
    }
}
