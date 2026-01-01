//
//  HTTPHeadersTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - HTTPHeadersTests

struct HTTPHeadersTests {
    // MARK: - Initialization Tests

    @Test("빈 HTTPHeaders 인스턴스 생성")
    func emptyInitialization() {
        // Given & When
        let headers = HTTPHeaders()

        // Then
        #expect(headers.build().isEmpty)
    }

    @Test("딕셔너리로 HTTPHeaders 인스턴스 생성")
    func initializationWithDictionary() {
        // Given
        let initialHeaders = ["X-Custom": "value", "Accept": "application/json"]

        // When
        let headers = HTTPHeaders(headers: initialHeaders)

        // Then
        let built = headers.build()
        #expect(built["X-Custom"] == "value")
        #expect(built["Accept"] == "application/json")
    }

    // MARK: - Method Chaining Tests

    @Test("contentType 메서드 체이닝")
    func contentTypeChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .contentType(.json)

        // Then
        let built = headers.build()
        #expect(built["Content-Type"] == "application/json; charset=UTF-8")
    }

    @Test("accept 메서드 체이닝")
    func acceptChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .accept(.json)

        // Then
        let built = headers.build()
        #expect(built["Accept"] == "application/json")
    }

    @Test("authorization 메서드 체이닝")
    func authorizationChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .authorization("Bearer token123")

        // Then
        let built = headers.build()
        #expect(built["Authorization"] == "Bearer token123")
    }

    @Test("userAgent 메서드 체이닝")
    func userAgentChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .userAgent("NetworkKit/1.0")

        // Then
        let built = headers.build()
        #expect(built["User-Agent"] == "NetworkKit/1.0")
    }

    @Test("acceptLanguage 메서드 체이닝")
    func acceptLanguageChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .acceptLanguage("ko-KR,ko;q=0.9")

        // Then
        let built = headers.build()
        #expect(built["Accept-Language"] == "ko-KR,ko;q=0.9")
    }

    @Test("appVersion 메서드 체이닝")
    func appVersionChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .appVersion("1.0.0")

        // Then
        let built = headers.build()
        #expect(built["X-App-Version"] == "1.0.0")
    }

    @Test("deviceModel 메서드 체이닝")
    func deviceModelChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .deviceModel("iPhone15,2")

        // Then
        let built = headers.build()
        #expect(built["X-Device-Model"] == "iPhone15,2")
    }

    @Test("osVersion 메서드 체이닝")
    func osVersionChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .osVersion("17.0")

        // Then
        let built = headers.build()
        #expect(built["X-OS-Version"] == "17.0")
    }

    @Test("bundleId 메서드 체이닝")
    func bundleIdChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .bundleId("com.example.app")

        // Then
        let built = headers.build()
        #expect(built["X-Bundle-Id"] == "com.example.app")
    }

    @Test("requestId 메서드 체이닝 - 커스텀 ID")
    func requestIdChainingCustom() {
        // Given & When
        let customId = "custom-request-id-123"
        let headers = HTTPHeaders()
            .requestId(customId)

        // Then
        let built = headers.build()
        #expect(built["X-Request-Id"] == customId)
    }

    @Test("requestId 메서드 체이닝 - 기본 UUID")
    func requestIdChainingDefault() {
        // Given & When
        let headers = HTTPHeaders()
            .requestId()

        // Then
        let built = headers.build()
        #expect(built["X-Request-Id"] != nil)
        #expect(built["X-Request-Id"]?.isEmpty == false)
    }

    @Test("timestamp 메서드 체이닝 - 커스텀 값")
    func timestampChainingCustom() {
        // Given & When
        let customTimestamp = "1705123456"
        let headers = HTTPHeaders()
            .timestamp(customTimestamp)

        // Then
        let built = headers.build()
        #expect(built["X-Timestamp"] == customTimestamp)
    }

    @Test("timestamp 메서드 체이닝 - 기본 값")
    func timestampChainingDefault() {
        // Given & When
        let headers = HTTPHeaders()
            .timestamp()

        // Then
        let built = headers.build()
        #expect(built["X-Timestamp"] != nil)
    }

    @Test("sessionId 메서드 체이닝")
    func sessionIdChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .sessionId("session-123")

        // Then
        let built = headers.build()
        #expect(built["X-Session-Id"] == "session-123")
    }

    @Test("clientVersion 메서드 체이닝")
    func clientVersionChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .clientVersion("2.0.0")

        // Then
        let built = headers.build()
        #expect(built["X-Client-Version"] == "2.0.0")
    }

    @Test("platform 메서드 체이닝")
    func platformChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .platform("iOS")

        // Then
        let built = headers.build()
        #expect(built["X-Platform"] == "iOS")
    }

    @Test("custom 메서드 체이닝")
    func customChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .custom(key: "X-Custom-Header", value: "custom-value")

        // Then
        let built = headers.build()
        #expect(built["X-Custom-Header"] == "custom-value")
    }

    @Test("merge 메서드 체이닝")
    func mergeChaining() {
        // Given
        let additionalHeaders = ["X-Extra-1": "value1", "X-Extra-2": "value2"]

        // When
        let headers = HTTPHeaders()
            .contentType(.json)
            .merge(with: additionalHeaders)

        // Then
        let built = headers.build()
        #expect(built["Content-Type"] == "application/json; charset=UTF-8")
        #expect(built["X-Extra-1"] == "value1")
        #expect(built["X-Extra-2"] == "value2")
    }

    @Test("merge 메서드 - 기존 값 덮어쓰기")
    func mergeOverwritesExistingValue() {
        // Given
        let additionalHeaders = ["Accept": "text/plain"]

        // When
        let headers = HTTPHeaders()
            .accept(.json)
            .merge(with: additionalHeaders)

        // Then
        let built = headers.build()
        #expect(built["Accept"] == "text/plain")
    }

    // MARK: - Convenience Methods Tests

    @Test("defaults 메서드 - JSON Content-Type 및 Accept 설정")
    func defaultsMethod() {
        // Given & When
        let headers = HTTPHeaders()
            .defaults()

        // Then
        let built = headers.build()
        #expect(built["Content-Type"] == "application/json; charset=UTF-8")
        #expect(built["Accept"] == "application/json")
    }

    @Test("form 메서드 - Form URL Encoded 설정")
    func formMethod() {
        // Given & When
        let headers = HTTPHeaders()
            .form()

        // Then
        let built = headers.build()
        #expect(built["Content-Type"] == "application/x-www-form-urlencoded; charset=UTF-8")
        #expect(built["Accept"] == "application/json")
    }

    @Test("multipart 메서드 - 커스텀 boundary")
    func multipartMethodCustomBoundary() {
        // Given
        let boundary = "CustomBoundary123"

        // When
        let headers = HTTPHeaders()
            .multipart(boundary: boundary)

        // Then
        let built = headers.build()
        #expect(built["Content-Type"] == "multipart/form-data; boundary=\(boundary)")
        #expect(built["Accept"] == "application/json")
    }

    @Test("multipart 메서드 - 기본 boundary")
    func multipartMethodDefaultBoundary() {
        // Given & When
        let headers = HTTPHeaders()
            .multipart()

        // Then
        let built = headers.build()
        #expect(built["Content-Type"]?.contains("multipart/form-data; boundary=") == true)
        #expect(built["Accept"] == "application/json")
    }

    @Test("authenticated 메서드")
    func authenticatedMethod() {
        // Given
        let token = "Bearer secret-token"

        // When
        let headers = HTTPHeaders()
            .authenticated(token: token)

        // Then
        let built = headers.build()
        #expect(built["Content-Type"] == "application/json; charset=UTF-8")
        #expect(built["Accept"] == "application/json")
        #expect(built["Authorization"] == token)
    }

    // MARK: - Static Methods Tests

    @Test("defaultHeaders 정적 메서드")
    func staticDefaultHeaders() {
        // Given & When
        let headers = HTTPHeaders.defaultHeaders()

        // Then
        #expect(headers["Content-Type"] == "application/json; charset=UTF-8")
        #expect(headers["Accept"] == "application/json")
    }

    @Test("authenticatedHeaders 정적 메서드 - 토큰 있음")
    func staticAuthenticatedHeadersWithToken() {
        // Given
        let token = "Bearer token"

        // When
        let headers = HTTPHeaders.authenticatedHeaders(accKey: token)

        // Then
        #expect(headers["Content-Type"] == "application/json; charset=UTF-8")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Authorization"] == token)
    }

    @Test("authenticatedHeaders 정적 메서드 - 토큰 없음")
    func staticAuthenticatedHeadersWithoutToken() {
        // Given & When
        let headers = HTTPHeaders.authenticatedHeaders(accKey: nil)

        // Then
        #expect(headers["Content-Type"] == "application/json; charset=UTF-8")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Authorization"] == nil)
    }

    @Test("formHeaders 정적 메서드 - 토큰 있음")
    func staticFormHeadersWithToken() {
        // Given
        let token = "Bearer form-token"

        // When
        let headers = HTTPHeaders.formHeaders(accKey: token)

        // Then
        #expect(headers["Content-Type"] == "application/x-www-form-urlencoded; charset=UTF-8")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Authorization"] == token)
    }

    @Test("formHeaders 정적 메서드 - 토큰 없음")
    func staticFormHeadersWithoutToken() {
        // Given & When
        let headers = HTTPHeaders.formHeaders(accKey: nil)

        // Then
        #expect(headers["Content-Type"] == "application/x-www-form-urlencoded; charset=UTF-8")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Authorization"] == nil)
    }

    @Test("multipartHeaders 정적 메서드 - 커스텀 boundary 및 토큰")
    func staticMultipartHeadersWithBoundaryAndToken() {
        // Given
        let boundary = "TestBoundary"
        let token = "Bearer multipart-token"

        // When
        let headers = HTTPHeaders.multipartHeaders(boundary: boundary, accKey: token)

        // Then
        #expect(headers["Content-Type"] == "multipart/form-data; boundary=\(boundary)")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Authorization"] == token)
    }

    // MARK: - ContentType Tests

    @Test("ContentType withUTF8 - JSON")
    func contentTypeWithUTF8Json() {
        // Given & When
        let contentType = HTTPHeaders.ContentType.json

        // Then
        #expect(contentType.rawValue == "application/json")
        #expect(contentType.withUTF8 == "application/json; charset=UTF-8")
    }

    @Test("ContentType withUTF8 - Form URL Encoded")
    func contentTypeWithUTF8FormURLEncoded() {
        // Given & When
        let contentType = HTTPHeaders.ContentType.formURLEncoded

        // Then
        #expect(contentType.rawValue == "application/x-www-form-urlencoded")
        #expect(contentType.withUTF8 == "application/x-www-form-urlencoded; charset=UTF-8")
    }

    @Test("ContentType withUTF8 - Text Plain")
    func contentTypeWithUTF8TextPlain() {
        // Given & When
        let contentType = HTTPHeaders.ContentType.textPlain

        // Then
        #expect(contentType.rawValue == "text/plain")
        #expect(contentType.withUTF8 == "text/plain; charset=UTF-8")
    }

    @Test("ContentType withUTF8 - Form Data")
    func contentTypeWithUTF8FormData() {
        // Given & When
        let contentType = HTTPHeaders.ContentType.formData

        // Then
        #expect(contentType.rawValue == "multipart/form-data")
        #expect(contentType.withUTF8 == "multipart/form-data")
    }

    // MARK: - HeaderKey Tests

    @Test("HeaderKey rawValue 확인", arguments: HTTPHeaders.HeaderKey.allCases)
    func headerKeyRawValues(key: HTTPHeaders.HeaderKey) {
        // Then
        #expect(key.rawValue.isEmpty == false)
    }

    // MARK: - Complex Chaining Tests

    @Test("복합 메서드 체이닝")
    func complexChaining() {
        // Given & When
        let headers = HTTPHeaders()
            .contentType(.json)
            .accept(.json)
            .authorization("Bearer token")
            .userAgent("NetworkKit/1.0")
            .appVersion("1.0.0")
            .platform("iOS")
            .requestId("req-123")
            .custom(key: "X-Custom", value: "custom")

        // Then
        let built = headers.build()
        #expect(built.count == 8)
        #expect(built["Content-Type"] == "application/json; charset=UTF-8")
        #expect(built["Accept"] == "application/json")
        #expect(built["Authorization"] == "Bearer token")
        #expect(built["User-Agent"] == "NetworkKit/1.0")
        #expect(built["X-App-Version"] == "1.0.0")
        #expect(built["X-Platform"] == "iOS")
        #expect(built["X-Request-Id"] == "req-123")
        #expect(built["X-Custom"] == "custom")
    }
}
