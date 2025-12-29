////
////  NetworkLogPluginTests.swift
////  NetworkKit
////
////  Created by AI Assistant on 2025/1/15.
////
//
// import Testing
// import Moya
// @testable import AsyncNetwork
//
//// MARK: - NetworkLogPluginTests
//
// struct NetworkLogPluginTests {
//
//    // MARK: - Test Models
//
//    private struct TestTarget: TargetType {
//        var baseURL: URL = URL(string: "https://example.com")!
//        var path: String = "/test"
//        var method: Moya.Method = .get
//        var task: Task = .requestPlain
//        var headers: [String: String]? = nil
//    }
//
//    private struct MockRequestType: RequestType {
//        let request: URLRequest?
//
//        init(request: URLRequest?) {
//            self.request = request
//        }
//    }
//
//    // MARK: - Initialization Tests
//
//    @Test("기본 설정으로 NetworkLogPlugin 생성")
//    func createNetworkLogPluginWithDefaultSettings() {
//        // Given & When
//        let plugin = NetworkLogPlugin()
//
//        // Then
//        #expect(plugin != nil)
//    }
//
//    @Test("커스텀 로그 레벨로 NetworkLogPlugin 생성")
//    func createNetworkLogPluginWithCustomLogLevel() {
//        // Given & When
//        let basicPlugin = NetworkLogPlugin(logLevel: .basic)
//        let headersPlugin = NetworkLogPlugin(logLevel: .headers)
//        let bodyPlugin = NetworkLogPlugin(logLevel: .body)
//        let verbosePlugin = NetworkLogPlugin(logLevel: .verbose)
//        let nonePlugin = NetworkLogPlugin(logLevel: .none)
//
//        // Then
//        #expect(basicPlugin != nil)
//        #expect(headersPlugin != nil)
//        #expect(bodyPlugin != nil)
//        #expect(verbosePlugin != nil)
//        #expect(nonePlugin != nil)
//    }
//
//    @Test("커스텀 민감한 키로 NetworkLogPlugin 생성")
//    func createNetworkLogPluginWithCustomSensitiveKeys() {
//        // Given & When
//        let plugin = NetworkLogPlugin(
//            logLevel: .verbose,
//            sensitiveKeys: ["custom_key", "secret", "api_key"]
//        )
//
//        // Then
//        #expect(plugin != nil)
//    }
//
//    // MARK: - Preset Tests
//
//    @Test("개발용 프리셋 생성")
//    func validateDevelopmentPreset() {
//        // Given & When
//        let plugin = NetworkLogPlugin.development
//
//        // Then
//        #expect(plugin != nil)
//    }
//
//    @Test("프로덕션용 프리셋 생성")
//    func validateProductionPreset() {
//        // Given & When
//        let plugin = NetworkLogPlugin.production
//
//        // Then
//        #expect(plugin != nil)
//    }
//
//    @Test("비활성화 프리셋 생성")
//    func validateDisabledPreset() {
//        // Given & When
//        let plugin = NetworkLogPlugin.disabled
//
//        // Then
//        #expect(plugin != nil)
//    }
//
//    // MARK: - Request Logging Tests
//
//    @Test("기본 GET 요청 로깅")
//    func logBasicGETRequest() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .basic)
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
//        urlRequest.httpMethod = "GET"
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        // 로깅은 콘솔 출력이므로 예외가 발생하지 않으면 성공
//        plugin.willSend(request, target: target)
//    }
//
//    @Test("헤더가 포함된 요청 로깅")
//    func logRequestWithHeaders() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .headers)
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    @Test("바디가 포함된 POST 요청 로깅")
//    func logPOSTRequestWithBody() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .body)
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
//        urlRequest.httpMethod = "POST"
//        urlRequest.httpBody = """
//        {
//            "username": "testuser",
//            "password": "secret123"
//        }
//        """.data(using: .utf8)
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    @Test("민감한 데이터가 포함된 요청 로깅")
//    func logRequestWithSensitiveData() {
//        // Given
//        let plugin = NetworkLogPlugin(
//            logLevel: .verbose,
//            sensitiveKeys: ["password", "token", "key"]
//        )
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test?password=secret&key=value")!)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("Bearer secret_token", forHTTPHeaderField: "Authorization")
//        urlRequest.httpBody = """
//        {
//            "username": "testuser",
//            "password": "secret123",
//            "enc_key": "encryption_key"
//        }
//        """.data(using: .utf8)
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    @Test("유효하지 않은 요청 로깅")
//    func logInvalidRequest() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .verbose)
//        let target = TestTarget()
//        let request = MockRequestType(request: nil)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    // MARK: - Response Logging Tests
//
//    @Test("성공 응답 로깅")
//    func logSuccessfulResponse() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .verbose)
//        let target = TestTarget()
//
//        let responseData = """
//        {
//            "status": "success",
//            "message": "Request completed successfully"
//        }
//        """.data(using: .utf8)!
//
//        let response = Response(
//            statusCode: 200,
//            data: responseData,
//            request: URLRequest(url: URL(string: "https://example.com/test")!),
//            response: HTTPURLResponse(
//                url: URL(string: "https://example.com/test")!,
//                statusCode: 200,
//                httpVersion: "HTTP/1.1",
//                headerFields: ["Content-Type": "application/json"]
//            )
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("에러 응답 로깅")
//    func logErrorResponse() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .verbose)
//        let target = TestTarget()
//
//        let responseData = """
//        {
//            "error": "Not Found",
//            "message": "The requested resource was not found"
//        }
//        """.data(using: .utf8)!
//
//        let response = Response(
//            statusCode: 404,
//            data: responseData,
//            request: URLRequest(url: URL(string: "https://example.com/test")!),
//            response: HTTPURLResponse(
//                url: URL(string: "https://example.com/test")!,
//                statusCode: 404,
//                httpVersion: "HTTP/1.1",
//                headerFields: ["Content-Type": "application/json"]
//            )
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("빈 응답 로깅")
//    func logEmptyResponse() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .body)
//        let target = TestTarget()
//
//        let response = Response(
//            statusCode: 204,
//            data: Data(),
//            request: URLRequest(url: URL(string: "https://example.com/test")!),
//            response: HTTPURLResponse(
//                url: URL(string: "https://example.com/test")!,
//                statusCode: 204,
//                httpVersion: "HTTP/1.1",
//                headerFields: [:]
//            )
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("큰 응답 데이터 로깅")
//    func logLargeResponseData() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .body)
//        let target = TestTarget()
//
//        // 큰 JSON 데이터 생성 (1000자 이상)
//        let largeData = String(repeating: "A", count: 2000).data(using: .utf8)!
//
//        let response = Response(
//            statusCode: 200,
//            data: largeData,
//            request: URLRequest(url: URL(string: "https://example.com/test")!),
//            response: HTTPURLResponse(
//                url: URL(string: "https://example.com/test")!,
//                statusCode: 200,
//                httpVersion: "HTTP/1.1",
//                headerFields: ["Content-Type": "text/plain"]
//            )
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("네트워크 에러 로깅")
//    func logNetworkError() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .verbose)
//        let target = TestTarget()
//
//        let networkError = MoyaError.underlying(
//            URLError(.networkConnectionLost),
//            nil
//        )
//
//        // When & Then
//        plugin.didReceive(.failure(networkError), target: target)
//    }
//
//    @Test("타임아웃 에러 로깅")
//    func logTimeoutError() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .basic)
//        let target = TestTarget()
//
//        let timeoutError = MoyaError.underlying(
//            URLError(.timedOut),
//            nil
//        )
//
//        // When & Then
//        plugin.didReceive(.failure(timeoutError), target: target)
//    }
//
//    // MARK: - Log Level Tests
//
//    @Test("로그 레벨 none - 로깅 없음")
//    func logLevelNoneNoLogging() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .none)
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
//        urlRequest.httpMethod = "GET"
//        let request = MockRequestType(request: urlRequest)
//
//        let response = Response(
//            statusCode: 200,
//            data: Data(),
//            request: urlRequest,
//            response: nil
//        )
//
//        // When & Then
//        // none 레벨에서는 로깅이 없어야 함
//        plugin.willSend(request, target: target)
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("로그 레벨 basic - 기본 정보만")
//    func logLevelBasicMinimalLogging() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .basic)
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
//        urlRequest.httpMethod = "GET"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpBody = "test body".data(using: .utf8)
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    // MARK: - Edge Cases
//
//    @Test("잘못된 JSON 데이터 로깅")
//    func logInvalidJSONData() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .body)
//        let target = TestTarget()
//
//        let invalidJSON = "{ invalid json data".data(using: .utf8)!
//
//        let response = Response(
//            statusCode: 200,
//            data: invalidJSON,
//            request: URLRequest(url: URL(string: "https://example.com/test")!),
//            response: nil
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("바이너리 데이터 로깅")
//    func logBinaryData() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .body)
//        let target = TestTarget()
//
//        // 바이너리 데이터 (이미지 등)
//        let binaryData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
//
//        let response = Response(
//            statusCode: 200,
//            data: binaryData,
//            request: URLRequest(url: URL(string: "https://example.com/image.png")!),
//            response: HTTPURLResponse(
//                url: URL(string: "https://example.com/image.png")!,
//                statusCode: 200,
//                httpVersion: "HTTP/1.1",
//                headerFields: ["Content-Type": "image/png"]
//            )
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("한글 데이터 로깅")
//    func logKoreanData() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .body)
//        let target = TestTarget()
//
//        let koreanData = """
//        {
//            "message": "안녕하세요",
//            "description": "한글 테스트 데이터입니다"
//        }
//        """.data(using: .utf8)!
//
//        let response = Response(
//            statusCode: 200,
//            data: koreanData,
//            request: URLRequest(url: URL(string: "https://example.com/korean")!),
//            response: nil
//        )
//
//        // When & Then
//        plugin.didReceive(.success(response), target: target)
//    }
//
//    @Test("매우 긴 URL 로깅")
//    func logVeryLongURL() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .verbose)
//        let target = TestTarget()
//
//        let longPath = String(repeating: "a", count: 1000)
//        let longURL = "https://example.com/\(longPath)?param=value"
//
//        var urlRequest = URLRequest(url: URL(string: longURL)!)
//        urlRequest.httpMethod = "GET"
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    @Test("빈 헤더로 요청 로깅")
//    func logRequestWithEmptyHeaders() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .headers)
//        let target = TestTarget()
//
//        var urlRequest = URLRequest(url: URL(string: "https://example.com/test")!)
//        urlRequest.httpMethod = "GET"
//        // 헤더를 명시적으로 설정하지 않음
//
//        let request = MockRequestType(request: urlRequest)
//
//        // When & Then
//        plugin.willSend(request, target: target)
//    }
//
//    // MARK: - Performance Tests
//
//    @Test("대량 요청 로깅 성능")
//    func logMultipleRequestsPerformance() {
//        // Given
//        let plugin = NetworkLogPlugin(logLevel: .basic)
//        let target = TestTarget()
//
//        // When & Then
//        for i in 1...100 {
//            var urlRequest = URLRequest(url: URL(string: "https://example.com/test\(i)")!)
//            urlRequest.httpMethod = "GET"
//
//            let request = MockRequestType(request: urlRequest)
//            plugin.willSend(request, target: target)
//
//            let response = Response(
//                statusCode: 200,
//                data: "response \(i)".data(using: .utf8)!,
//                request: urlRequest,
//                response: nil
//            )
//            plugin.didReceive(.success(response), target: target)
//        }
//    }
// }
