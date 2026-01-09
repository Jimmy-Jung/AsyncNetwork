//
//  PropertyWrappersTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - PropertyWrappersTests

/// Property Wrapper들의 동작 테스트
struct PropertyWrappersTests {
    // MARK: - Test Models

    private struct TestRequest: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/test" // placeholder 없는 기본 path
        var method: HTTPMethod = .get

        @QueryParameter var search: String?
        @QueryParameter var limit: Int?
        @QueryParameter var isActive: Bool?

        var id: Int
        var user: String

        @HeaderField(key: .authorization) var authorization: String?
        @HeaderField(key: .contentType) var contentType: String?
        @CustomHeader("X-Custom-Header") var customHeader: String?

        @RequestBody var body: TestBody?

        init(id: Int = 0, user: String = "") {
            self.id = id
            self.user = user
        }
    }

    private struct TestRequestWithRequiredQuery: APIRequest {
        var baseURLString: String = "https://api.example.com"
        var path: String = "/test"
        var method: HTTPMethod = .get

        @QueryParameter var userId: Int?
        @QueryParameter var name: String?
        @QueryParameter var page: Int?

        init(userId: Int, name: String, page: Int? = nil) {
            self._userId = QueryParameter(wrappedValue: userId)
            self._name = QueryParameter(wrappedValue: name)
            self._page = QueryParameter(wrappedValue: page)
        }
    }

    private struct TestBody: Codable, Sendable {
        let name: String
        let value: Int
    }

    // MARK: - QueryParameter Tests

    @Test("QueryParameter - 단일 파라미터 적용")
    func queryParameterSingleValue() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.search = "test"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        #expect(queryItems?.contains(where: { $0.name == "search" && $0.value == "test" }) == true)
    }

    @Test("QueryParameter - 여러 파라미터 적용")
    func queryParameterMultipleValues() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.search = "test"
        request.limit = 10
        request.isActive = true

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        #expect(queryItems?.contains(where: { $0.name == "search" && $0.value == "test" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "limit" && $0.value == "10" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "isActive" && $0.value == "true" }) == true)
    }

    @Test("QueryParameter - nil 값은 적용되지 않음")
    func queryParameterNilValue() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.search = nil
        request.limit = nil

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        #expect(queryItems == nil || queryItems?.isEmpty == true)
    }

    @Test("QueryParameter - 특수 문자 인코딩")
    func queryParameterSpecialCharacters() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.search = "hello world & test"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        // URL 인코딩되어야 함
        #expect(urlString.contains("hello%20world") || urlString.contains("hello+world"))
    }
    
    @Test("QueryParameter - Non-optional 필수 파라미터")
    func queryParameterRequiredValues() throws {
        // Given
        let request = TestRequestWithRequiredQuery(userId: 123, name: "john", page: 5)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 필수 파라미터는 항상 존재
        #expect(queryItems?.contains(where: { $0.name == "userId" && $0.value == "123" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "name" && $0.value == "john" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "page" && $0.value == "5" }) == true)
    }
    
    @Test("QueryParameter - Non-optional과 Optional 혼합")
    func queryParameterMixedRequiredAndOptional() throws {
        // Given
        let request = TestRequestWithRequiredQuery(userId: 456, name: "alice", page: nil)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 필수 파라미터는 존재하고, optional nil은 없음
        #expect(queryItems?.contains(where: { $0.name == "userId" && $0.value == "456" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "name" && $0.value == "alice" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "page" }) == false)
    }

    // MARK: - Multiple PropertyWrappers Tests

    @Test("QueryParameter + HeaderField 조합")
    func queryParameterWithHeaders() throws {
        // Given
        var request = TestRequest()
        request.search = "test query"
        request.authorization = "Bearer token123"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        #expect(queryItems?.contains(where: { $0.name == "search" }) == true)
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
    }

    @Test("RequestBody + HeaderField 조합")
    func requestBodyWithHeaders() throws {
        // Given
        var request = TestRequest()
        request.body = TestBody(name: "Test", value: 42)
        request.contentType = "application/json; charset=utf-8"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpBody != nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json; charset=utf-8")
    }

    // MARK: - HeaderField Tests

    @Test("HeaderField - Authorization 헤더 적용")
    func headerFieldAuthorization() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.authorization = "Bearer token123"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
    }

    @Test("HeaderField - Content-Type 헤더 적용")
    func headerFieldContentType() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.contentType = "application/json"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("HeaderField - 여러 헤더 동시 적용")
    func headerFieldMultipleHeaders() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.authorization = "Bearer token123"
        request.contentType = "application/json"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("HeaderField - nil 값은 적용되지 않음")
    func headerFieldNilValue() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.authorization = nil
        request.contentType = nil

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    // MARK: - CustomHeader Tests

    @Test("CustomHeader - 커스텀 헤더 적용")
    func customHeaderApply() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.customHeader = "CustomValue"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "CustomValue")
    }

    @Test("CustomHeader - nil 값은 적용되지 않음")
    func customHeaderNilValue() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.customHeader = nil

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == nil)
    }

    // MARK: - RequestBody Tests

    @Test("RequestBody - JSON 바디 적용")
    func requestBodyJSONApply() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.body = TestBody(name: "Test", value: 42)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)

        #expect(decodedBody.name == "Test")
        #expect(decodedBody.value == 42)
    }

    @Test("RequestBody - nil 값은 적용되지 않음")
    func requestBodyNilValue() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.body = nil

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpBody == nil)
    }

    @Test("RequestBody - Content-Type 자동 설정")
    func requestBodyContentType() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.body = TestBody(name: "Test", value: 42)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.contains("application/json") == true)
    }

    // MARK: - Combined Tests

    @Test("모든 PropertyWrapper 동시 적용")
    func allPropertyWrappersCombined() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.search = "test"
        request.limit = 10
        request.authorization = "Bearer token"
        request.contentType = "application/json"
        request.customHeader = "CustomValue"
        request.body = TestBody(name: "Test", value: 42)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        // Query Parameters
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        let hasSearch = queryItems?.contains(where: { $0.name == "search" && $0.value == "test" }) ?? false
        let hasLimit = queryItems?.contains(where: { $0.name == "limit" && $0.value == "10" }) ?? false
        #expect(hasSearch == true)
        #expect(hasLimit == true)

        // Headers
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "CustomValue")

        // Body
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)
        #expect(decodedBody.name == "Test")
        #expect(decodedBody.value == 42)
    }
}
