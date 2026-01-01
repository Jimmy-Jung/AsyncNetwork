//
//  NetworkLogPluginTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - NetworkLogPluginTests (ConsoleLoggingInterceptor)

struct NetworkLogPluginTests {
    // MARK: - Test Models

    private struct TestAPIRequest: APIRequest {
        var baseURLString: String = "https://example.com"
        var path: String = "/test"
        var method: HTTPMethod = .get
        var task: HTTPTask = .requestPlain
        var headers: [String: String]? = nil
    }

    // MARK: - Initialization Tests

    @Test("기본 설정으로 ConsoleLoggingInterceptor 생성")
    func createConsoleLoggingInterceptorWithDefaultSettings() {
        // Given & When
        let interceptor = ConsoleLoggingInterceptor()

        // Then
        #expect(interceptor != nil)
    }

    @Test("커스텀 로그 레벨로 ConsoleLoggingInterceptor 생성")
    func createConsoleLoggingInterceptorWithCustomLogLevel() {
        // Given & When
        let verboseInterceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let debugInterceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let infoInterceptor = ConsoleLoggingInterceptor(minimumLevel: .info)
        let warningInterceptor = ConsoleLoggingInterceptor(minimumLevel: .warning)
        let errorInterceptor = ConsoleLoggingInterceptor(minimumLevel: .error)

        // Then
        #expect(verboseInterceptor != nil)
        #expect(debugInterceptor != nil)
        #expect(infoInterceptor != nil)
        #expect(warningInterceptor != nil)
        #expect(errorInterceptor != nil)
    }

    @Test("커스텀 민감한 키로 ConsoleLoggingInterceptor 생성")
    func createConsoleLoggingInterceptorWithCustomSensitiveKeys() {
        // Given & When
        let interceptor = ConsoleLoggingInterceptor(
            minimumLevel: .verbose,
            sensitiveKeys: ["custom_key", "secret", "api_key"]
        )

        // Then
        #expect(interceptor != nil)
    }

    // MARK: - Request Logging Tests

    @Test("기본 GET 요청 로깅")
    func logBasicGETRequest() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
        urlRequest.httpMethod = "GET"

        // When & Then
        // 로깅은 콘솔 출력이므로 예외가 발생하지 않으면 성공
        await interceptor.willSend(urlRequest, target: request)
    }

    @Test("헤더가 포함된 요청 로깅")
    func logRequestWithHeaders() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer token123", forHTTPHeaderField: "Authorization")

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    @Test("바디가 포함된 POST 요청 로깅")
    func logPOSTRequestWithBody() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = """
        {
            "username": "testuser",
            "password": "secret123"
        }
        """.data(using: .utf8)

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    @Test("민감한 데이터가 포함된 요청 로깅")
    func logRequestWithSensitiveData() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(
            minimumLevel: .verbose,
            sensitiveKeys: ["password", "token", "key"]
        )
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test?password=secret&key=value")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer secret_token", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = """
        {
            "username": "testuser",
            "password": "secret123",
            "enc_key": "encryption_key"
        }
        """.data(using: .utf8)

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    @Test("유효하지 않은 요청 로깅")
    func logInvalidRequest() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let request = TestAPIRequest()
        let urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    // MARK: - Response Logging Tests

    @Test("성공 응답 로깅")
    func logSuccessfulResponse() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let request = TestAPIRequest()

        let responseData = """
        {
            "status": "success",
            "message": "Request completed successfully"
        }
        """.data(using: .utf8)!

        let response = HTTPResponse(
            statusCode: 200,
            data: responseData,
            request: URLRequest(url: URL(string: "https://example.com/test")!),
            response: HTTPURLResponse(
                url: URL(string: "https://example.com/test")!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    @Test("에러 응답 로깅")
    func logErrorResponse() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let request = TestAPIRequest()

        let responseData = """
        {
            "error": "Not Found",
            "message": "The requested resource was not found"
        }
        """.data(using: .utf8)!

        let response = HTTPResponse(
            statusCode: 404,
            data: responseData,
            request: URLRequest(url: URL(string: "https://example.com/test")!),
            response: HTTPURLResponse(
                url: URL(string: "https://example.com/test")!,
                statusCode: 404,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    @Test("빈 응답 로깅")
    func logEmptyResponse() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        let response = HTTPResponse(
            statusCode: 204,
            data: Data(),
            request: URLRequest(url: URL(string: "https://example.com/test")!),
            response: HTTPURLResponse(
                url: URL(string: "https://example.com/test")!,
                statusCode: 204,
                httpVersion: "HTTP/1.1",
                headerFields: [:]
            )
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    @Test("큰 응답 데이터 로깅")
    func logLargeResponseData() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        // 큰 JSON 데이터 생성 (1000자 이상)
        let largeData = String(repeating: "A", count: 2000).data(using: .utf8)!

        let response = HTTPResponse(
            statusCode: 200,
            data: largeData,
            request: URLRequest(url: URL(string: "https://example.com/test")!),
            response: HTTPURLResponse(
                url: URL(string: "https://example.com/test")!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/plain"]
            )
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    // MARK: - Log Level Tests

    @Test("로그 레벨 info - 로깅 없음")
    func logLevelInfoNoLogging() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .info)
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
        urlRequest.httpMethod = "GET"

        let response = HTTPResponse(
            statusCode: 200,
            data: Data(),
            request: urlRequest,
            response: nil
        )

        // When & Then
        // info 레벨에서는 debug 로깅이 없어야 함
        await interceptor.willSend(urlRequest, target: request)
        await interceptor.didReceive(response, target: request)
    }

    @Test("로그 레벨 debug - 기본 정보만")
    func logLevelDebugMinimalLogging() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "test body".data(using: .utf8)

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    // MARK: - Edge Cases

    @Test("잘못된 JSON 데이터 로깅")
    func logInvalidJSONData() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        let invalidJSON = "{ invalid json data".data(using: .utf8)!

        let response = HTTPResponse(
            statusCode: 200,
            data: invalidJSON,
            request: URLRequest(url: URL(string: "https://example.com/test")!),
            response: nil
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    @Test("바이너리 데이터 로깅")
    func logBinaryData() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        // 바이너리 데이터 (이미지 등)
        let binaryData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        let response = HTTPResponse(
            statusCode: 200,
            data: binaryData,
            request: URLRequest(url: URL(string: "https://example.com/image.png")!),
            response: HTTPURLResponse(
                url: URL(string: "https://example.com/image.png")!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "image/png"]
            )
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    @Test("한글 데이터 로깅")
    func logKoreanData() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        let koreanData = """
        {
            "message": "안녕하세요",
            "description": "한글 테스트 데이터입니다"
        }
        """.data(using: .utf8)!

        let response = HTTPResponse(
            statusCode: 200,
            data: koreanData,
            request: URLRequest(url: URL(string: "https://example.com/korean")!),
            response: nil
        )

        // When & Then
        await interceptor.didReceive(response, target: request)
    }

    @Test("매우 긴 URL 로깅")
    func logVeryLongURL() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .verbose)
        let request = TestAPIRequest()

        let longPath = String(repeating: "a", count: 1000)
        let longURL = "https://example.com/\(longPath)?param=value"

        var urlRequest = URLRequest(url: URL(string: longURL)!)
        urlRequest.httpMethod = "GET"

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    @Test("빈 헤더로 요청 로깅")
    func logRequestWithEmptyHeaders() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
        urlRequest.httpMethod = "GET"
        // 헤더를 명시적으로 설정하지 않음

        // When & Then
        await interceptor.willSend(urlRequest, target: request)
    }

    // MARK: - Performance Tests

    @Test("대량 요청 로깅 성능")
    func logMultipleRequestsPerformance() async {
        // Given
        let interceptor = ConsoleLoggingInterceptor(minimumLevel: .debug)
        let request = TestAPIRequest()

        // When & Then
        for i in 1 ... 100 {
            var urlRequest = URLRequest(url: URL(string: "https://example.com/test\(i)")!)
            urlRequest.httpMethod = "GET"

            await interceptor.willSend(urlRequest, target: request)

            let response = HTTPResponse(
                statusCode: 200,
                data: "response \(i)".data(using: .utf8)!,
                request: urlRequest,
                response: nil
            )
            await interceptor.didReceive(response, target: request)
        }
    }
}
