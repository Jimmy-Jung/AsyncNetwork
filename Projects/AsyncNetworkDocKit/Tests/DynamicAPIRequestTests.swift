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

    @Test("query parameters만 있을 때 requestQueryParameters task가 생성된다")
    func queryParametersTaskIsCreated() {
        let queryParams = ["page": "1", "limit": "10"]
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get,
            queryParameters: queryParams
        )

        if case let .requestQueryParameters(parameters) = request.task {
            #expect(parameters == queryParams)
        } else {
            Issue.record("Expected requestQueryParameters task")
        }
    }

    @Test("빈 query parameters일 때 requestPlain task가 생성된다")
    func emptyQueryParametersCreatesPlainTask() {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get,
            queryParameters: [:]
        )

        if case .requestPlain = request.task {
            // Success
        } else {
            Issue.record("Expected requestPlain task")
        }
    }

    @Test("body가 있을 때 requestData task가 생성된다")
    func bodyDataTaskIsCreated() {
        let bodyData = "{\"name\": \"John\"}".data(using: .utf8)!
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .post,
            body: bodyData
        )

        if case let .requestData(data) = request.task {
            #expect(data == bodyData)
        } else {
            Issue.record("Expected requestData task")
        }
    }

    @Test("body와 query parameters가 모두 있을 때 body가 우선된다")
    func bodyTakesPrecedenceOverQueryParameters() {
        let bodyData = "{\"name\": \"John\"}".data(using: .utf8)!
        let queryParams = ["page": "1"]
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .post,
            queryParameters: queryParams,
            body: bodyData
        )

        if case let .requestData(data) = request.task {
            #expect(data == bodyData)
        } else {
            Issue.record("Expected requestData task (body should take precedence)")
        }
    }

    @Test("body와 query parameters가 없을 때 requestPlain task가 생성된다")
    func plainTaskIsCreatedWhenNoBodyOrQuery() {
        let request = DynamicAPIRequest(
            baseURL: "https://api.example.com",
            path: "/users",
            method: .get
        )

        if case .requestPlain = request.task {
            // Success
        } else {
            Issue.record("Expected requestPlain task")
        }
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

        if case let .requestData(data) = request.task {
            #expect(data == bodyData)
        } else {
            Issue.record("Expected requestData task")
        }
    }
}
