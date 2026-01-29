//
//  HeaderFieldTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

/// HeaderField Property Wrapper 테스트
@Suite("HeaderField Tests")
struct HeaderFieldTests {
    @Test("HeaderField - Authorization 헤더 적용")
    func authorization() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.authorization = "Bearer token123"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
    }

    @Test("HeaderField - Content-Type 헤더 적용")
    func contentType() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.contentType = "application/json"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("HeaderField - 여러 헤더 동시 적용")
    func multipleHeaders() throws {
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
    func nilValue() throws {
        // Given
        struct SimpleRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/test"
            var method: HTTPMethod = .get

            @HeaderField(key: .authorization) var authorization: String?
            @HeaderField(key: .contentType) var contentType: String?

            init() {}
        }

        var request = SimpleRequest()
        request.authorization = nil
        request.contentType = nil

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    @Test("HeaderField - 특수 문자가 포함된 값")
    func specialCharacters() throws {
        // Given
        var request = TestRequest()
        request.authorization = "Bearer token-with-special_chars.123"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token-with-special_chars.123")
    }

    @Test("HeaderField - 긴 값 처리")
    func longValue() throws {
        // Given
        var request = TestRequest()
        let longToken = String(repeating: "a", count: 1000)
        request.authorization = "Bearer \(longToken)"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let authHeader = urlRequest.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader?.hasPrefix("Bearer a") == true)
        #expect(authHeader?.count == 1007) // "Bearer " (7) + 1000
    }

    @Test("HeaderField - 다양한 타입 (String, Int) 처리")
    func variousTypes() throws {
        // Given
        var request = TestRequest()
        request.authorization = "Bearer token"

        // When
        var urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")

        // 수동으로 다른 타입 추가 테스트
        urlRequest.setValue("12345", forHTTPHeaderField: "X-Request-ID")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Request-ID") == "12345")
    }
}
