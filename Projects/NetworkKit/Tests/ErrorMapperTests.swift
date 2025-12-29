////
////  ErrorMapperTests.swift
////  NetworkKit
////
////  Created by AI Assistant on 2025/1/15.
////
//
// import Testing
// import Moya
// @testable import NetworkKit
//
//// MARK: - ErrorMapperTests
//
// struct ErrorMapperTests {
//
//    // MARK: - Properties
//
//    private let errorMapper = ErrorMapper()
//    private let silentErrorMapper = ErrorMapper.silent
//
//    // MARK: - StatusCodeValidationError Mapping Tests
//
//    @Test("StatusCodeValidationError를 NetworkError.httpError로 매핑")
//    func mapStatusCodeValidationErrorToHttpError() {
//        // Given
//        let statusError = StatusCodeValidationError.clientError(400, "test data".data(using: .utf8))
//
//        // When
//        let mappedError = errorMapper.mapError(statusError)
//
//        // Then
//        switch mappedError {
//        case .httpError(let httpError):
//            #expect(httpError.statusCode == 400)
//        default:
//            #expect(Bool(false), "StatusCodeValidationError는 httpError로 매핑되어야 함")
//        }
//    }
//
//    @Test("StatusCodeValidationError 서버 에러는 재시도 가능")
//    func mapStatusCodeValidationServerErrorAsRetryable() {
//        // Given
//        let serverError = StatusCodeValidationError.serverError(500, Data())
//
//        // When
//        let mappedError = errorMapper.mapError(serverError)
//
//        // Then
//        #expect(mappedError.isRetryable == true)
//    }
//
//    @Test("StatusCodeValidationError 클라이언트 에러는 재시도 불가")
//    func mapStatusCodeValidationClientErrorAsNotRetryable() {
//        // Given
//        let clientError = StatusCodeValidationError.clientError(400, Data())
//
//        // When
//        let mappedError = errorMapper.mapError(clientError)
//
//        // Then
//        #expect(mappedError.isRetryable == false)
//    }
//
//    // MARK: - DecodingError Mapping Tests
//
//    @Test("DecodingError를 NetworkError.decodingError로 매핑")
//    func mapDecodingErrorToDecodingError() {
//        // Given
//        let decodingError = DecodingError.dataCorrupted(
//            DecodingError.Context(
//                codingPath: [],
//                debugDescription: "Test decoding error"
//            )
//        )
//
//        // When
//        let mappedError = errorMapper.mapError(decodingError)
//
//        // Then
//        switch mappedError {
//        case .decodingError(let error):
//            #expect(error is DecodingError)
//        default:
//            #expect(Bool(false), "DecodingError는 decodingError로 매핑되어야 함")
//        }
//    }
//
//    @Test("DecodingError는 재시도 불가")
//    func mapDecodingErrorAsNotRetryable() {
//        // Given
//        let decodingError = DecodingError.dataCorrupted(
//            DecodingError.Context(
//                codingPath: [],
//                debugDescription: "Test decoding error"
//            )
//        )
//
//        // When
//        let mappedError = errorMapper.mapError(decodingError)
//
//        // Then
//        #expect(mappedError.isRetryable == false)
//    }
//
//    // MARK: - QubeServerError Mapping Tests
//
//    @Test("QubeServerError를 NetworkError.qubeServerError로 매핑")
//    func mapQubeServerErrorToQubeServerError() {
//        // Given
//        let qubeError = QubeServerError(
//            result: "1001",
//            msg: "Test error message",
//            description: "Test description"
//        )
//
//        // When
//        let mappedError = errorMapper.mapError(qubeError)
//
//        // Then
//        switch mappedError {
//        case .qubeServerError(let error):
//            #expect(error.result == "1001")
//            #expect(error.msg == "Test error message")
//        default:
//            #expect(Bool(false), "QubeServerError는 qubeServerError로 매핑되어야 함")
//        }
//    }
//
//    @Test("QubeServerError 재시도 가능 여부 확인")
//    func mapQubeServerErrorRetryableStatus() {
//        // Given
//        let retryableError = QubeServerError(
//            result: "5001",
//            msg: "Temporary server error",
//            description: "Server temporarily unavailable"
//        )
//        retryableError.isRetryable = true
//
//        let nonRetryableError = QubeServerError(
//            result: "1001",
//            msg: "Invalid request",
//            description: "Bad request"
//        )
//        nonRetryableError.isRetryable = false
//
//        // When
//        let mappedRetryableError = errorMapper.mapError(retryableError)
//        let mappedNonRetryableError = errorMapper.mapError(nonRetryableError)
//
//        // Then
//        #expect(mappedRetryableError.isRetryable == true)
//        #expect(mappedNonRetryableError.isRetryable == false)
//    }
//
//    // MARK: - URLError Mapping Tests
//
//    @Test("URLError를 NetworkError.connectionError로 매핑")
//    func mapURLErrorToConnectionError() {
//        // Given
//        let urlError = URLError(.networkConnectionLost)
//
//        // When
//        let mappedError = errorMapper.mapError(urlError)
//
//        // Then
//        switch mappedError {
//        case .connectionError(let error):
//            #expect(error.code == .networkConnectionLost)
//        default:
//            #expect(Bool(false), "URLError는 connectionError로 매핑되어야 함")
//        }
//    }
//
//    @Test("URLError는 재시도 가능")
//    func mapURLErrorAsRetryable() {
//        // Given
//        let urlError = URLError(.networkConnectionLost)
//
//        // When
//        let mappedError = errorMapper.mapError(urlError)
//
//        // Then
//        #expect(mappedError.isRetryable == true)
//    }
//
//    @Test("다양한 URLError 코드 매핑", arguments: [
//        URLError.networkConnectionLost,
//        URLError.timedOut,
//        URLError.cannotFindHost,
//        URLError.cannotConnectToHost,
//        URLError.dnsLookupFailed,
//        URLError.notConnectedToInternet
//    ])
//    func mapVariousURLErrorCodes(urlErrorCode: URLError.Code) {
//        // Given
//        let urlError = URLError(urlErrorCode)
//
//        // When
//        let mappedError = errorMapper.mapError(urlError)
//
//        // Then
//        switch mappedError {
//        case .connectionError(let error):
//            #expect(error.code == urlErrorCode)
//        default:
//            #expect(Bool(false), "URLError는 connectionError로 매핑되어야 함")
//        }
//    }
//
//    // MARK: - MoyaError Mapping Tests
//
//    @Test("MoyaError.statusCode를 NetworkError.moyaError로 매핑")
//    func mapMoyaErrorStatusCodeToMoyaError() {
//        // Given
//        let response = createMockResponse(statusCode: 500)
//        let moyaError = MoyaError.statusCode(response)
//
//        // When
//        let mappedError = errorMapper.mapError(moyaError)
//
//        // Then
//        switch mappedError {
//        case .moyaError(let error):
//            if case .statusCode(let response) = error {
//                #expect(response.statusCode == 500)
//            } else {
//                #expect(Bool(false), "MoyaError.statusCode가 올바르게 매핑되어야 함")
//            }
//        default:
//            #expect(Bool(false), "MoyaError는 moyaError로 매핑되어야 함")
//        }
//    }
//
//    @Test("MoyaError.underlying은 내부 에러를 재귀적으로 매핑")
//    func mapMoyaErrorUnderlyingRecursively() {
//        // Given
//        let underlyingError = URLError(.networkConnectionLost)
//        let moyaError = MoyaError.underlying(underlyingError, nil)
//
//        // When
//        let mappedError = errorMapper.mapError(moyaError)
//
//        // Then
//        switch mappedError {
//        case .connectionError(let error):
//            #expect(error.code == .networkConnectionLost)
//        default:
//            #expect(Bool(false), "MoyaError.underlying은 내부 에러로 매핑되어야 함")
//        }
//    }
//
//    @Test("MoyaError 5xx 상태 코드는 재시도 가능")
//    func mapMoyaError5xxAsRetryable() {
//        // Given
//        let response = createMockResponse(statusCode: 500)
//        let moyaError = MoyaError.statusCode(response)
//
//        // When
//        let mappedError = errorMapper.mapError(moyaError)
//
//        // Then
//        #expect(mappedError.isRetryable == true)
//    }
//
//    @Test("MoyaError 4xx 상태 코드는 재시도 불가")
//    func mapMoyaError4xxAsNotRetryable() {
//        // Given
//        let response = createMockResponse(statusCode: 400)
//        let moyaError = MoyaError.statusCode(response)
//
//        // When
//        let mappedError = errorMapper.mapError(moyaError)
//
//        // Then
//        #expect(mappedError.isRetryable == false)
//    }
//
//    // MARK: - QubeAPI Error Mapping Tests
//
//    @Test("QubeAPI 에러 매핑에 errorMap 적용")
//    func mapQubeAPIErrorWithErrorMap() {
//        // Given
//        let qubeError = QubeServerError(
//            result: "1001",
//            msg: "Original error message",
//            description: "Original description"
//        )
//
//        let mockRequest = MockQubeAPIRequest()
//        mockRequest.errorMap = ["1001": "Mapped error message"]
//
//        // When
//        let mappedError = errorMapper.mapQubeError(qubeError, request: mockRequest)
//
//        // Then
//        switch mappedError {
//        case .qubeServerError(let error):
//            #expect(error.result == "1001")
//            #expect(error.msg == "Original error message")
//            #expect(error.description == "Mapped error message")
//        default:
//            #expect(Bool(false), "QubeAPI 에러는 qubeServerError로 매핑되어야 함")
//        }
//    }
//
//    @Test("QubeAPI 에러 매핑에서 errorMap에 없는 에러는 원본 유지")
//    func mapQubeAPIErrorWithoutErrorMap() {
//        // Given
//        let qubeError = QubeServerError(
//            result: "9999",
//            msg: "Unknown error",
//            description: "Unknown description"
//        )
//
//        let mockRequest = MockQubeAPIRequest()
//        mockRequest.errorMap = ["1001": "Mapped error message"]
//
//        // When
//        let mappedError = errorMapper.mapQubeError(qubeError, request: mockRequest)
//
//        // Then
//        switch mappedError {
//        case .qubeServerError(let error):
//            #expect(error.result == "9999")
//            #expect(error.msg == "Unknown error")
//            #expect(error.description == "Unknown description")
//        default:
//            #expect(Bool(false), "QubeAPI 에러는 qubeServerError로 매핑되어야 함")
//        }
//    }
//
//    // MARK: - Unknown Error Mapping Tests
//
//    @Test("알 수 없는 에러를 NetworkError.unknown으로 매핑")
//    func mapUnknownErrorToUnknown() {
//        // Given
//        struct CustomError: Error {
//            let message: String
//        }
//        let customError = CustomError(message: "Custom error")
//
//        // When
//        let mappedError = errorMapper.mapError(customError)
//
//        // Then
//        switch mappedError {
//        case .unknown(let error):
//            #expect(error is CustomError)
//        default:
//            #expect(Bool(false), "알 수 없는 에러는 unknown으로 매핑되어야 함")
//        }
//    }
//
//    @Test("알 수 없는 에러는 재시도 불가")
//    func mapUnknownErrorAsNotRetryable() {
//        // Given
//        struct CustomError: Error {
//            let message: String
//        }
//        let customError = CustomError(message: "Custom error")
//
//        // When
//        let mappedError = errorMapper.mapError(customError)
//
//        // Then
//        #expect(mappedError.isRetryable == false)
//    }
//
//    // MARK: - NetworkError Passthrough Tests
//
//    @Test("이미 매핑된 NetworkError는 그대로 반환")
//    func passThroughAlreadyMappedNetworkError() {
//        // Given
//        let originalNetworkError = NetworkError.unknown(NSError(domain: "test", code: 1))
//
//        // When
//        let mappedError = errorMapper.mapError(originalNetworkError)
//
//        // Then
//        switch mappedError {
//        case .unknown(let error):
//            #expect(error is NSError)
//        default:
//            #expect(Bool(false), "이미 매핑된 NetworkError는 그대로 반환되어야 함")
//        }
//    }
//
//    // MARK: - Error Description Tests
//
//    @Test("NetworkError 에러 설명 확인")
//    func validateNetworkErrorDescriptions() {
//        // Given
//        let statusError = StatusCodeValidationError.clientError(400, Data())
//        let decodingError = DecodingError.dataCorrupted(
//            DecodingError.Context(codingPath: [], debugDescription: "Test")
//        )
//        let qubeError = QubeServerError(result: "1001", msg: "Test", description: "Test")
//        let urlError = URLError(.networkConnectionLost)
//        let moyaError = MoyaError.requestMapping("Test")
//        let unknownError = NSError(domain: "test", code: 1)
//
//        // When
//        let statusMappedError = errorMapper.mapError(statusError)
//        let decodingMappedError = errorMapper.mapError(decodingError)
//        let qubeMappedError = errorMapper.mapError(qubeError)
//        let urlMappedError = errorMapper.mapError(urlError)
//        let moyaMappedError = errorMapper.mapError(moyaError)
//        let unknownMappedError = errorMapper.mapError(unknownError)
//
//        // Then
//        #expect(statusMappedError.errorDescription?.contains("HTTP Error") == true)
//        #expect(decodingMappedError.errorDescription?.contains("Decoding Error") == true)
//        #expect(qubeMappedError.errorDescription?.contains("Server Error") == true)
//        #expect(urlMappedError.errorDescription?.contains("Connection Error") == true)
//        #expect(moyaMappedError.errorDescription?.contains("Network Error") == true)
//        #expect(unknownMappedError.errorDescription?.contains("Unknown Error") == true)
//    }
//
//    // MARK: - Retryable Check Tests
//
//    @Test("isRetryable 메서드 테스트")
//    func validateIsRetryableMethod() {
//        // Given
//        let retryableError = URLError(.networkConnectionLost)
//        let nonRetryableError = DecodingError.dataCorrupted(
//            DecodingError.Context(codingPath: [], debugDescription: "Test")
//        )
//
//        // When & Then
//        #expect(errorMapper.isRetryable(retryableError) == true)
//        #expect(errorMapper.isRetryable(nonRetryableError) == false)
//    }
//
//    // MARK: - Preset Tests
//
//    @Test("기본 ErrorMapper 생성")
//    func validateDefaultErrorMapperCreation() {
//        // Given & When
//        let mapper = ErrorMapper.default
//
//        // Then
//        #expect(mapper != nil)
//    }
//
//    @Test("조용한 ErrorMapper 생성")
//    func validateSilentErrorMapperCreation() {
//        // Given & When
//        let mapper = ErrorMapper.silent
//
//        // Then
//        #expect(mapper != nil)
//    }
// }
//
//// MARK: - Mock QubeAPIRequest
//
// private struct MockQubeAPIRequest: QubeAPIRequest {
//    var domain: QubeDomain = .question
//    var urlPath: String = "/test"
//    var errorMap: [String: String] = [:]
//
//    var task: Task {
//        return .requestPlain
//    }
// }
//
//// MARK: - Helper Methods
//
// private extension ErrorMapperTests {
//    /// Mock Response 생성
//    func createMockResponse(statusCode: Int) -> Response {
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
//            data: "test".data(using: .utf8)!,
//            request: URLRequest(url: url),
//            response: httpResponse
//        )
//    }
// }
