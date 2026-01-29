//
//  QueryParameterBasicTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

@Suite("QueryParameter Basic Tests")
struct QueryParameterBasicTests {
    @Test("QueryParameter - 단일 파라미터 적용")
    func singleValue() throws {
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
    func multipleValues() throws {
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
    func nilValue() throws {
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
    func specialCharacters() throws {
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
    func requiredValues() throws {
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
    func mixedRequiredAndOptional() throws {
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

    @Test("QueryParameter - 커스텀 키 사용")
    func customKey() throws {
        // Given
        var request = TestRequestWithCustomKeyQuery()
        request.searchTerm = "swift programming"
        request.itemsPerPage = 25

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 커스텀 키로 변환되어야 함
        #expect(queryItems?.contains(where: { $0.name == "q" && $0.value == "swift programming" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "per_page" && $0.value == "25" }) == true)

        // 원래 프로퍼티 이름은 사용되지 않음
        #expect(queryItems?.contains(where: { $0.name == "searchTerm" }) == false)
        #expect(queryItems?.contains(where: { $0.name == "itemsPerPage" }) == false)
    }

    @Test("QueryParameter - 다양한 타입 지원 (String, Int, Bool)")
    func variousTypes() throws {
        // Given
        var request = TestRequest()
        request.search = "test"
        request.limit = 100
        request.isActive = false

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        #expect(queryItems?.contains(where: { $0.name == "search" && $0.value == "test" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "limit" && $0.value == "100" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "isActive" && $0.value == "false" }) == true)
    }

    @Test("QueryParameter - 빈 문자열 처리")
    func emptyString() throws {
        // Given
        var request = TestRequest()
        request.search = ""

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        // 빈 문자열도 유효한 값으로 추가되어야 함
        #expect(queryItems?.contains(where: { $0.name == "search" && $0.value == "" }) == true)
    }

    @Test("QueryParameter + HeaderField 조합")
    func withHeaders() throws {
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
}
