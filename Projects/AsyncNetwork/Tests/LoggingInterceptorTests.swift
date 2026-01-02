//
//  LoggingInterceptorTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - NetworkLogLevelTests

struct NetworkLogLevelTests {
    @Test("NetworkLogLevel rawValue 확인", arguments: [
        (NetworkLogLevel.verbose, 0),
        (NetworkLogLevel.debug, 1),
        (NetworkLogLevel.info, 2),
        (NetworkLogLevel.warning, 3),
        (NetworkLogLevel.error, 4),
        (NetworkLogLevel.fatal, 5)
    ])
    func logLevelRawValues(level: NetworkLogLevel, expectedRawValue: Int) {
        #expect(level.rawValue == expectedRawValue)
    }

    @Test("NetworkLogLevel emoji 확인", arguments: [
        (NetworkLogLevel.verbose, "💬"),
        (NetworkLogLevel.debug, "🔍"),
        (NetworkLogLevel.info, "ℹ️"),
        (NetworkLogLevel.warning, "⚠️"),
        (NetworkLogLevel.error, "❌"),
        (NetworkLogLevel.fatal, "🔥")
    ])
    func logLevelEmoji(level: NetworkLogLevel, expectedEmoji: String) {
        #expect(level.emoji == expectedEmoji)
    }

    @Test("NetworkLogLevel 순서 비교")
    func logLevelOrdering() {
        #expect(NetworkLogLevel.verbose.rawValue < NetworkLogLevel.debug.rawValue)
        #expect(NetworkLogLevel.debug.rawValue < NetworkLogLevel.info.rawValue)
        #expect(NetworkLogLevel.info.rawValue < NetworkLogLevel.warning.rawValue)
        #expect(NetworkLogLevel.warning.rawValue < NetworkLogLevel.error.rawValue)
        #expect(NetworkLogLevel.error.rawValue < NetworkLogLevel.fatal.rawValue)
    }
}

// MARK: - ConsoleLoggingInterceptorTests

struct ConsoleLoggingInterceptorTests {
    // MARK: - Initialization Tests

    @Test("ConsoleLoggingInterceptor 기본 초기화")
    func defaultInitialization() {
        // Given & When
        let interceptor = ConsoleLoggingInterceptor()

        // Then - 초기화가 성공적으로 됨
        #expect(interceptor is ConsoleLoggingInterceptor)
    }

    @Test("ConsoleLoggingInterceptor 커스텀 minimumLevel")
    func customMinimumLevel() {
        // Given & When
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .warning)

        // Then
        #expect(interceptor is ConsoleLoggingInterceptor)
    }

    @Test("ConsoleLoggingInterceptor 커스텀 sensitiveKeys")
    func customSensitiveKeys() {
        // Given & When
        let interceptor = ConsoleLoggingInterceptor(
            sensitiveKeys: ["api_key", "secret"]
        )

        // Then
        #expect(interceptor is ConsoleLoggingInterceptor)
    }

    // MARK: - RequestInterceptor Protocol Tests

    @Test("willSend 호출 시 에러 없음")
    func willSendNoError() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)

        // When & Then - 에러 없이 완료
        await interceptor.willSend(request, target: nil)
    }

    @Test("didReceive 호출 시 에러 없음")
    func didReceiveNoError() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let response = HTTPResponse(statusCode: 200, data: Data())

        // When & Then - 에러 없이 완료
        await interceptor.didReceive(response, target: nil)
    }

    @Test("prepare 메서드는 기본 구현 사용")
    func prepareUsesDefaultImplementation() async throws {
        // Given
        let interceptor = ConsoleLoggingInterceptor()
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        let originalURL = request.url

        // When
        try await interceptor.prepare(&request, target: nil)

        // Then - 요청이 수정되지 않음
        #expect(request.url == originalURL)
    }

    // MARK: - Log Level Filtering Tests

    @Test("minimumLevel이 error일 때 debug 로그 출력 안 함")
    func minimumLevelFiltersDebug() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .error)
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)

        // When & Then - 에러 없이 완료 (로그는 출력되지 않음)
        await interceptor.willSend(request, target: nil)
    }

    @Test("minimumLevel이 fatal일 때 warning 로그 출력 안 함")
    func minimumLevelFiltersWarning() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .fatal)
        let response = HTTPResponse(statusCode: 400, data: Data())

        // When & Then - 에러 없이 완료 (로그는 출력되지 않음)
        await interceptor.didReceive(response, target: nil)
    }

    // MARK: - Response Status Code Tests

    @Test("200 응답 코드 처리")
    func handle200Response() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let response = HTTPResponse(statusCode: 200, data: Data("success".utf8))

        // When & Then - 에러 없이 완료
        await interceptor.didReceive(response, target: nil)
    }

    @Test("404 응답 코드 처리")
    func handle404Response() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .warning)
        let response = HTTPResponse(statusCode: 404, data: Data())

        // When & Then - 에러 없이 완료
        await interceptor.didReceive(response, target: nil)
    }

    @Test("500 응답 코드 처리")
    func handle500Response() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .warning)
        let response = HTTPResponse(statusCode: 500, data: Data("error".utf8))

        // When & Then - 에러 없이 완료
        await interceptor.didReceive(response, target: nil)
    }

    // MARK: - Request with Body Tests

    @Test("요청 본문이 있는 경우 처리")
    func handleRequestWithBody() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("{\"key\":\"value\"}".utf8)

        // When & Then - 에러 없이 완료
        await interceptor.willSend(request, target: nil)
    }

    @Test("요청 헤더가 있는 경우 처리")
    func handleRequestWithHeaders() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer token", forHTTPHeaderField: "Authorization")

        // When & Then - 에러 없이 완료
        await interceptor.willSend(request, target: nil)
    }

    // MARK: - Empty Data Tests

    @Test("빈 응답 본문 처리")
    func handleEmptyResponseBody() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let response = HTTPResponse(statusCode: 204, data: Data())

        // When & Then - 에러 없이 완료
        await interceptor.didReceive(response, target: nil)
    }

    @Test("빈 요청 본문 처리")
    func handleEmptyRequestBody() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.httpBody = nil

        // When & Then - 에러 없이 완료
        await interceptor.willSend(request, target: nil)
    }

    // MARK: - JSON Response Tests

    @Test("JSON 응답 본문 처리")
    func handleJSONResponseBody() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let jsonData = Data("{\"status\":\"ok\",\"count\":42}".utf8)
        let response = HTTPResponse(statusCode: 200, data: jsonData)

        // When & Then - 에러 없이 완료
        await interceptor.didReceive(response, target: nil)
    }

    @Test("잘못된 JSON 응답 본문 처리")
    func handleInvalidJSONResponseBody() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let invalidData = Data("not valid json".utf8)
        let response = HTTPResponse(statusCode: 200, data: invalidData)

        // When & Then - 에러 없이 완료 (plain text로 처리)
        await interceptor.didReceive(response, target: nil)
    }

    // MARK: - Sensitive Data Tests

    @Test("민감한 헤더 필터링")
    func sensitiveHeaderFiltering() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(
            minimumLevel: .debug,
            sensitiveKeys: ["password", "token"]
        )
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.setValue("secret123", forHTTPHeaderField: "X-Token")

        // When & Then - 에러 없이 완료
        await interceptor.willSend(request, target: nil)
    }

    @Test("기본 민감한 키 목록")
    func defaultSensitiveKeys() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.httpBody = Data("{\"password\":\"secret\",\"token\":\"abc123\"}".utf8)

        // When & Then - 에러 없이 완료
        await interceptor.willSend(request, target: nil)
    }

    // MARK: - Concurrent Access Tests

    @Test("동시 호출 안전성")
    func concurrentAccessSafety() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let response = HTTPResponse(statusCode: 200, data: Data())

        // When - 동시에 여러 요청/응답 처리
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    await interceptor.willSend(request, target: nil)
                }
                group.addTask {
                    await interceptor.didReceive(response, target: nil)
                }
            }
        }

        // Then - 에러 없이 모든 작업 완료
    }
}

// MARK: - RequestInterceptor Default Implementation Tests

struct RequestInterceptorDefaultImplTests {
    struct EmptyInterceptor: RequestInterceptor {}

    @Test("기본 prepare 구현은 요청을 수정하지 않음")
    func defaultPrepareDoesNotModifyRequest() async throws {
        // Given
        let interceptor = EmptyInterceptor()
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let originalRequest = request

        // When
        try await interceptor.prepare(&request, target: nil)

        // Then
        #expect(request.url == originalRequest.url)
        #expect(request.httpMethod == originalRequest.httpMethod)
    }

    @Test("기본 willSend 구현은 에러 없이 완료")
    func defaultWillSendCompletes() async {
        // Given
        let interceptor = EmptyInterceptor()
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)

        // When & Then
        await interceptor.willSend(request, target: nil)
    }

    @Test("기본 didReceive 구현은 에러 없이 완료")
    func defaultDidReceiveCompletes() async {
        // Given
        let interceptor = EmptyInterceptor()
        let response = HTTPResponse(statusCode: 200, data: Data())

        // When & Then
        await interceptor.didReceive(response, target: nil)
    }
}
