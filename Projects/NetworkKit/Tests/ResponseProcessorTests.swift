////
////  ResponseProcessorTests.swift
////  NetworkKit
////
////  Created by AI Assistant on 2025/1/15.
////
//
// import Testing
// import Moya
// @testable import NetworkKit
//
//// MARK: - ResponseProcessorTests
//
// struct ResponseProcessorTests {
//
//    // MARK: - Test Models
//
//    private struct TestUser: Codable, Equatable {
//        let id: Int
//        let name: String
//        let email: String
//    }
//
//    private struct TestServerResponse: ServerResponse, Codable, Equatable {
//        let result: String
//        let msg: String
//        let data: TestUser?
//    }
//
//    private struct TestAPIRequest: APIRequest {
//        var baseURL: URL = URL(string: "https://example.com")!
//        var path: String = "/test"
//        var method: Moya.Method = .get
//        var task: Task = .requestPlain
//        var headers: [String: String]? = nil
//    }
//
//    private struct TestQubeAPIRequest: QubeAPIRequest {
//        var domain: QubeDomain = .question
//        var urlPath: String = "/test"
//        var errorMap: [String: String] = ["1001": "Test error message"]
//
//        var task: Task = .requestPlain
//    }
//
//    // MARK: - GeneralResponseProcessor Tests
//
//    @Test("GeneralResponseProcessor 성공적인 응답 처리")
//    func generalResponseProcessorSuccess() {
//        // Given
//        let expectedUser = TestUser(id: 1, name: "John Doe", email: "john@example.com")
//        let response = createMockResponse(statusCode: 200, data: createUserJSONData())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let user):
//            #expect(user == expectedUser)
//        case .failure:
//            #expect(Bool(false), "성공적인 응답은 처리되어야 함")
//        }
//    }
//
//    @Test("GeneralResponseProcessor MoyaError 처리")
//    func generalResponseProcessorMoyaError() {
//        // Given
//        let moyaError = MoyaError.statusCode(createMockResponse(statusCode: 500))
//        let result: Result<Response, MoyaError> = .failure(moyaError)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "MoyaError는 실패로 처리되어야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
//
//    @Test("GeneralResponseProcessor 상태 코드 검증 실패")
//    func generalResponseProcessorStatusCodeValidationFailure() {
//        // Given
//        let response = createMockResponse(statusCode: 400, data: createUserJSONData())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "400 상태 코드는 실패로 처리되어야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
//
//    @Test("GeneralResponseProcessor 디코딩 실패")
//    func generalResponseProcessorDecodingFailure() {
//        // Given
//        let invalidJSONData = "invalid json".data(using: .utf8)!
//        let response = createMockResponse(statusCode: 200, data: invalidJSONData)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "잘못된 JSON은 실패로 처리되어야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
//
//    // MARK: - QubeResponseProcessor Tests
//
//    @Test("QubeResponseProcessor 성공적인 응답 처리")
//    func qubeResponseProcessorSuccess() {
//        // Given
//        let expectedResponse = TestServerResponse(
//            result: "0000",
//            msg: "Success",
//            data: TestUser(id: 1, name: "John Doe", email: "john@example.com")
//        )
//        let response = createMockResponse(statusCode: 200, data: createServerResponseJSONData())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = QubeResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestServerResponse.self,
//            request: TestQubeAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let serverResponse):
//            #expect(serverResponse.result == "0000")
//            #expect(serverResponse.msg == "Success")
//            #expect(serverResponse.data != nil)
//        case .failure:
//            #expect(Bool(false), "성공적인 Qube 응답은 처리되어야 함")
//        }
//    }
//
//    @Test("QubeResponseProcessor QubeAPIRequest가 아닌 요청 실패")
//    func qubeResponseProcessorNonQubeRequestFailure() {
//        // Given
//        let response = createMockResponse(statusCode: 200, data: createServerResponseJSONData())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = QubeResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestServerResponse.self,
//            request: TestAPIRequest() // 일반 API 요청
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "QubeAPIRequest가 아닌 요청은 실패해야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
//
//    @Test("QubeResponseProcessor 서버 에러 응답 처리")
//    func qubeResponseProcessorServerErrorResponse() {
//        // Given
//        let errorResponse = TestServerResponse(
//            result: "1001",
//            msg: "Server error",
//            data: nil
//        )
//        let response = createMockResponse(statusCode: 200, data: createErrorResponseJSONData())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = QubeResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestServerResponse.self,
//            request: TestQubeAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let serverResponse):
//            #expect(serverResponse.result == "1001")
//            #expect(serverResponse.msg == "Server error")
//            #expect(serverResponse.data == nil)
//        case .failure:
//            #expect(Bool(false), "서버 에러 응답도 성공적으로 처리되어야 함")
//        }
//    }
//
//    // MARK: - RawResponseProcessor Tests
//
//    @Test("RawResponseProcessor 성공적인 데이터 처리")
//    func rawResponseProcessorSuccess() {
//        // Given
//        let expectedData = "Hello, World!".data(using: .utf8)!
//        let response = createMockResponse(statusCode: 200, data: expectedData)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = RawResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: Data.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let data):
//            #expect(data == expectedData)
//        case .failure:
//            #expect(Bool(false), "성공적인 원시 데이터는 처리되어야 함")
//        }
//    }
//
//    @Test("RawResponseProcessor Data 타입이 아닌 경우 실패")
//    func rawResponseProcessorNonDataTypeFailure() {
//        // Given
//        let response = createMockResponse(statusCode: 200, data: "test".data(using: .utf8)!)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = RawResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self, // Data가 아닌 타입
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "Data 타입이 아닌 경우 실패해야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
//
//    @Test("RawResponseProcessor 빈 데이터 처리")
//    func rawResponseProcessorEmptyData() {
//        // Given
//        let emptyData = Data()
//        let response = createMockResponse(statusCode: 200, data: emptyData)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = RawResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: Data.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let data):
//            #expect(data.isEmpty == true)
//        case .failure:
//            #expect(Bool(false), "빈 데이터도 성공적으로 처리되어야 함")
//        }
//    }
//
//    // MARK: - ProcessingConfiguration Tests
//
//    @Test("기본 ProcessingConfiguration 생성")
//    func validateDefaultProcessingConfiguration() {
//        // Given & When
//        let config = ProcessingConfiguration.default
//
//        // Then
//        #expect(config.statusCodeValidator != nil)
//        #expect(config.responseDecoder != nil)
//        #expect(config.errorMapper != nil)
//        #expect(config.serverResponseValidator != nil)
//    }
//
//    @Test("커스텀 ProcessingConfiguration 생성")
//    func validateCustomProcessingConfiguration() {
//        // Given & When
//        let config = ProcessingConfiguration(
//            statusCodeValidator: .strict,
//            responseDecoder: .withDateFormat("yyyy-MM-dd"),
//            errorMapper: .silent,
//            serverResponseValidator: .silent
//        )
//
//        // Then
//        #expect(config.statusCodeValidator != nil)
//        #expect(config.responseDecoder != nil)
//        #expect(config.errorMapper != nil)
//        #expect(config.serverResponseValidator != nil)
//    }
//
//    // MARK: - Preset Tests
//
//    @Test("GeneralResponseProcessor 프리셋들")
//    func validateGeneralResponseProcessorPresets() {
//        // Given & When
//        let defaultProcessor = GeneralResponseProcessor.default
//        let strictProcessor = GeneralResponseProcessor.strict
//        let lenientProcessor = GeneralResponseProcessor.lenient
//        let silentProcessor = GeneralResponseProcessor.silent
//
//        // Then
//        #expect(defaultProcessor != nil)
//        #expect(strictProcessor != nil)
//        #expect(lenientProcessor != nil)
//        #expect(silentProcessor != nil)
//    }
//
//    @Test("QubeResponseProcessor 프리셋들")
//    func validateQubeResponseProcessorPresets() {
//        // Given & When
//        let defaultProcessor = QubeResponseProcessor.default
//        let strictProcessor = QubeResponseProcessor.strict
//        let lenientProcessor = QubeResponseProcessor.lenient
//        let silentProcessor = QubeResponseProcessor.silent
//
//        // Then
//        #expect(defaultProcessor != nil)
//        #expect(strictProcessor != nil)
//        #expect(lenientProcessor != nil)
//        #expect(silentProcessor != nil)
//    }
//
//    @Test("RawResponseProcessor 프리셋들")
//    func validateRawResponseProcessorPresets() {
//        // Given & When
//        let defaultProcessor = RawResponseProcessor.default
//        let strictProcessor = RawResponseProcessor.strict
//        let lenientProcessor = RawResponseProcessor.lenient
//        let silentProcessor = RawResponseProcessor.silent
//
//        // Then
//        #expect(defaultProcessor != nil)
//        #expect(strictProcessor != nil)
//        #expect(lenientProcessor != nil)
//        #expect(silentProcessor != nil)
//    }
//
//    // MARK: - Edge Cases
//
//    @Test("nil 요청으로 처리")
//    func processWithNilRequest() {
//        // Given
//        let response = createMockResponse(statusCode: 200, data: createUserJSONData())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: nil
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let user):
//            #expect(user.id == 1)
//        case .failure:
//            #expect(Bool(false), "nil 요청도 처리되어야 함")
//        }
//    }
//
//    @Test("큰 응답 데이터 처리")
//    func processLargeResponseData() {
//        // Given
//        let largeData = createLargeJSONData()
//        let response = createMockResponse(statusCode: 200, data: largeData)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = RawResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: Data.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let data):
//            #expect(data.count == largeData.count)
//        case .failure:
//            #expect(Bool(false), "큰 데이터도 처리되어야 함")
//        }
//    }
//
//    @Test("빈 응답 처리")
//    func processEmptyResponse() {
//        // Given
//        let emptyData = Data()
//        let response = createMockResponse(statusCode: 204, data: emptyData)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = RawResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: Data.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success(let data):
//            #expect(data.isEmpty == true)
//        case .failure:
//            #expect(Bool(false), "빈 응답도 처리되어야 함")
//        }
//    }
//
//    // MARK: - Error Propagation Tests
//
//    @Test("상태 코드 검증 에러 전파")
//    func propagateStatusCodeValidationError() {
//        // Given
//        let response = createMockResponse(statusCode: 500, data: Data())
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "500 상태 코드는 실패해야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
//
//    @Test("디코딩 에러 전파")
//    func propagateDecodingError() {
//        // Given
//        let invalidData = "invalid json".data(using: .utf8)!
//        let response = createMockResponse(statusCode: 200, data: invalidData)
//        let result: Result<Response, MoyaError> = .success(response)
//
//        let processor = GeneralResponseProcessor()
//
//        // When
//        let processedResult = processor.process(
//            result: result,
//            decodeType: TestUser.self,
//            request: TestAPIRequest()
//        )
//
//        // Then
//        switch processedResult {
//        case .success:
//            #expect(Bool(false), "잘못된 JSON은 실패해야 함")
//        case .failure(let error):
//            #expect(error is NetworkError)
//        }
//    }
// }
//
//// MARK: - Helper Methods
//
// private extension ResponseProcessorTests {
//    /// Mock Response 생성
//    func createMockResponse(statusCode: Int, data: Data) -> Response {
//        let url = URL(string: "https://example.com")!
//        let httpResponse = HTTPURLResponse(
//            url: url,
//            statusCode: statusCode,
//            httpVersion: "HTTP/1.1",
//            headerFields: [:]
//        )!
//
//        return Response(
//            statusCode: statusCode,
//            data: data,
//            request: URLRequest(url: url),
//            response: httpResponse
//        )
//    }
//
//    /// 사용자 JSON 데이터 생성
//    func createUserJSONData() -> Data {
//        let json = """
//        {
//            "id": 1,
//            "name": "John Doe",
//            "email": "john@example.com"
//        }
//        """
//        return json.data(using: .utf8)!
//    }
//
//    /// 서버 응답 JSON 데이터 생성
//    func createServerResponseJSONData() -> Data {
//        let json = """
//        {
//            "result": "0000",
//            "msg": "Success",
//            "data": {
//                "id": 1,
//                "name": "John Doe",
//                "email": "john@example.com"
//            }
//        }
//        """
//        return json.data(using: .utf8)!
//    }
//
//    /// 에러 응답 JSON 데이터 생성
//    func createErrorResponseJSONData() -> Data {
//        let json = """
//        {
//            "result": "1001",
//            "msg": "Server error",
//            "data": null
//        }
//        """
//        return json.data(using: .utf8)!
//    }
//
//    /// 큰 JSON 데이터 생성
//    func createLargeJSONData() -> Data {
//        var users: [[String: Any]] = []
//
//        for i in 1...1000 {
//            users.append([
//                "id": i,
//                "name": "User \(i)",
//                "email": "user\(i)@example.com"
//            ])
//        }
//
//        let jsonObject: [String: Any] = [
//            "users": users,
//            "count": 1000
//        ]
//
//        return try! JSONSerialization.data(withJSONObject: jsonObject)
//    }
// }
