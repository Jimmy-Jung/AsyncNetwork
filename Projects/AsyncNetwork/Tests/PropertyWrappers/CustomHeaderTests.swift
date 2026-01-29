//
//  CustomHeaderTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

/// CustomHeader Property Wrapper 테스트
@Suite("CustomHeader Tests")
struct CustomHeaderTests {
    @Test("CustomHeader - 커스텀 헤더 적용")
    func apply() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.customHeader = "CustomValue"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "CustomValue")
    }

    @Test("CustomHeader - nil 값은 적용되지 않음")
    func nilValue() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.customHeader = nil

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == nil)
    }

    @Test("CustomHeader - 여러 커스텀 헤더 동시 사용")
    func multiple() throws {
        // Given
        var request = TestRequest()
        request.customHeader = "Value1"

        // When
        var urlRequest = try request.asURLRequest()

        // 추가 커스텀 헤더 수동 설정 (테스트용)
        urlRequest.setValue("Value2", forHTTPHeaderField: "X-Another-Header")

        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "Value1")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Another-Header") == "Value2")
    }

    @Test("CustomHeader - 대소문자 구분 없음")
    func caseInsensitive() throws {
        // Given
        var request = TestRequest()
        request.customHeader = "TestValue"

        // When
        let urlRequest = try request.asURLRequest()

        // Then - HTTP 헤더는 대소문자를 구분하지 않음
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "TestValue")
        #expect(urlRequest.value(forHTTPHeaderField: "x-custom-header") == "TestValue")
        #expect(urlRequest.value(forHTTPHeaderField: "X-CUSTOM-HEADER") == "TestValue")
    }
}
