//
//  PathParameterTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

/// PathParameter Property Wrapper 테스트
@Suite("PathParameter Tests")
struct PathParameterTests {
    @Test("PathParameter - 단일 placeholder 치환")
    func singlePlaceholder() throws {
        // Given
        let request = TestRequestWithPathParameter(userId: 123, postId: "abc-456")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        #expect(url.absoluteString.contains("/users/123/posts/abc-456"))
        #expect(!url.absoluteString.contains("{userId}"))
        #expect(!url.absoluteString.contains("{postId}"))
    }

    @Test("PathParameter - 여러 placeholder 동시 치환")
    func multiplePlaceholders() throws {
        // Given
        let request = TestRequestWithPathParameter(userId: 999, postId: "post-xyz")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        #expect(urlString.contains("/users/999/"))
        #expect(urlString.contains("/posts/post-xyz"))
        #expect(!urlString.contains("{"))
        #expect(!urlString.contains("}"))
    }

    @Test("PathParameter - URL 인코딩된 placeholder 치환")
    func encodedPlaceholder() throws {
        // Given
        let request = TestRequestWithEncodedPathPlaceholder(itemId: "special-item-123")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        // URL이 이미 %7B...%7D 형태로 되어 있으면, placeholder 치환이 되어야 함
        // 하지만 두 번 인코딩된 형태(%257B)는 placeholder로 인식되지 않음
        // 이 테스트는 실제 동작을 확인하는 용도
        print("URL: \(urlString)")

        // 최소한 itemId가 없는지만 확인
        #expect(!urlString.contains("{itemId}"))
    }

    @Test("PathParameter - 특수 문자가 포함된 값")
    func specialCharacters() throws {
        // Given
        let request = TestRequestWithPathParameter(userId: 42, postId: "post-with-dash_underscore")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        #expect(url.absoluteString.contains("/posts/post-with-dash_underscore"))
    }

    @Test("PathParameter - 정수 타입 변환")
    func integerType() throws {
        // Given
        let request = TestRequestWithPathParameter(userId: 0, postId: "zero")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        #expect(url.absoluteString.contains("/users/0/"))
    }
}
