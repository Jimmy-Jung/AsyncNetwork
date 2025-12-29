//
//  ErrorMapperTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetwork
import Foundation
import Testing

// MARK: - ErrorMapperTests

struct ErrorMapperTests {
    // MARK: - Properties

    private let errorMapper = ErrorMapper()
    private let silentErrorMapper = ErrorMapper.silent

    // MARK: - StatusCodeValidationError Mapping Tests

    @Test("StatusCodeValidationError를 NetworkError.httpError로 매핑")
    func mapStatusCodeValidationErrorToHttpError() {
        // Given
        let statusError = StatusCodeValidationError.clientError(400, Data("test data".utf8))

        // When
        let mappedError = errorMapper.mapError(statusError)

        // Then
        switch mappedError {
        case let .httpError(httpError):
            #expect(httpError.statusCode == 400)
        default:
            Issue.record("StatusCodeValidationError는 httpError로 매핑되어야 함")
        }
    }

    @Test("StatusCodeValidationError 서버 에러는 재시도 가능")
    func mapStatusCodeValidationServerErrorAsRetryable() {
        // Given
        let serverError = StatusCodeValidationError.serverError(500, Data())

        // When
        let mappedError = errorMapper.mapError(serverError)

        // Then
        #expect(mappedError.isRetryable == true)
    }

    @Test("StatusCodeValidationError 클라이언트 에러는 재시도 불가")
    func mapStatusCodeValidationClientErrorAsNotRetryable() {
        // Given
        let clientError = StatusCodeValidationError.clientError(400, Data())

        // When
        let mappedError = errorMapper.mapError(clientError)

        // Then
        #expect(mappedError.isRetryable == false)
    }

    @Test("다양한 상태 코드 에러 매핑", arguments: [
        (StatusCodeValidationError.invalidStatusCode(100, nil), 100),
        (StatusCodeValidationError.clientError(404, nil), 404),
        (StatusCodeValidationError.serverError(502, nil), 502),
        (StatusCodeValidationError.unknownError(999, nil), 999)
    ])
    func mapVariousStatusCodeErrors(error: StatusCodeValidationError, expectedCode: Int) {
        // When
        let mappedError = errorMapper.mapError(error)

        // Then
        switch mappedError {
        case let .httpError(httpError):
            #expect(httpError.statusCode == expectedCode)
        default:
            Issue.record("StatusCodeValidationError는 httpError로 매핑되어야 함")
        }
    }

    // MARK: - DecodingError Mapping Tests

    @Test("DecodingError를 NetworkError.decodingError로 매핑")
    func mapDecodingErrorToDecodingError() {
        // Given
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Test decoding error"
            )
        )

        // When
        let mappedError = errorMapper.mapError(decodingError)

        // Then
        switch mappedError {
        case .decodingError:
            #expect(true)
        default:
            Issue.record("DecodingError는 decodingError로 매핑되어야 함")
        }
    }

    @Test("DecodingError는 재시도 불가")
    func mapDecodingErrorAsNotRetryable() {
        // Given
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Test decoding error"
            )
        )

        // When
        let mappedError = errorMapper.mapError(decodingError)

        // Then
        #expect(mappedError.isRetryable == false)
    }

    @Test("다양한 DecodingError 타입 매핑", arguments: [
        DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Test")),
        DecodingError.keyNotFound(
            CodingKeys.name,
            DecodingError.Context(codingPath: [], debugDescription: "Key not found")
        ),
        DecodingError.valueNotFound(
            String.self,
            DecodingError.Context(codingPath: [], debugDescription: "Value not found")
        ),
        DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(codingPath: [], debugDescription: "Type mismatch")
        )
    ])
    func mapVariousDecodingErrors(error: DecodingError) {
        // When
        let mappedError = errorMapper.mapError(error)

        // Then
        switch mappedError {
        case .decodingError:
            #expect(true)
        default:
            Issue.record("DecodingError는 decodingError로 매핑되어야 함")
        }
    }

    // MARK: - URLError Mapping Tests

    @Test("URLError를 NetworkError.connectionError로 매핑")
    func mapURLErrorToConnectionError() {
        // Given
        let urlError = URLError(.networkConnectionLost)

        // When
        let mappedError = errorMapper.mapError(urlError)

        // Then
        switch mappedError {
        case let .connectionError(error):
            #expect(error.code == .networkConnectionLost)
        default:
            Issue.record("URLError는 connectionError로 매핑되어야 함")
        }
    }

    @Test("URLError는 재시도 가능")
    func mapURLErrorAsRetryable() {
        // Given
        let urlError = URLError(.networkConnectionLost)

        // When
        let mappedError = errorMapper.mapError(urlError)

        // Then
        #expect(mappedError.isRetryable == true)
    }

    @Test("다양한 URLError 코드 매핑", arguments: [
        URLError.Code.networkConnectionLost,
        URLError.Code.timedOut,
        URLError.Code.cannotFindHost,
        URLError.Code.cannotConnectToHost,
        URLError.Code.dnsLookupFailed,
        URLError.Code.notConnectedToInternet
    ])
    func mapVariousURLErrorCodes(urlErrorCode: URLError.Code) {
        // Given
        let urlError = URLError(urlErrorCode)

        // When
        let mappedError = errorMapper.mapError(urlError)

        // Then
        switch mappedError {
        case let .connectionError(error):
            #expect(error.code == urlErrorCode)
        default:
            Issue.record("URLError는 connectionError로 매핑되어야 함")
        }
    }

    // MARK: - Unknown Error Mapping Tests

    @Test("알 수 없는 에러를 NetworkError.unknown으로 매핑")
    func mapUnknownErrorToUnknown() {
        // Given
        struct CustomError: Error {
            let message: String
        }
        let customError = CustomError(message: "Custom error")

        // When
        let mappedError = errorMapper.mapError(customError)

        // Then
        switch mappedError {
        case let .unknown(error):
            #expect(error is CustomError)
        default:
            Issue.record("알 수 없는 에러는 unknown으로 매핑되어야 함")
        }
    }

    @Test("알 수 없는 에러는 재시도 불가")
    func mapUnknownErrorAsNotRetryable() {
        // Given
        struct CustomError: Error {
            let message: String
        }
        let customError = CustomError(message: "Custom error")

        // When
        let mappedError = errorMapper.mapError(customError)

        // Then
        #expect(mappedError.isRetryable == false)
    }

    // MARK: - NetworkError Passthrough Tests

    @Test("이미 매핑된 NetworkError는 그대로 반환")
    func passThroughAlreadyMappedNetworkError() {
        // Given
        let originalNetworkError = NetworkError.unknown(NSError(domain: "test", code: 1))

        // When
        let mappedError = errorMapper.mapError(originalNetworkError)

        // Then
        switch mappedError {
        case let .unknown(error):
            #expect(error is NSError)
        default:
            Issue.record("이미 매핑된 NetworkError는 그대로 반환되어야 함")
        }
    }

    @Test("NetworkError.httpError 패스스루")
    func passThroughHttpError() {
        // Given
        let statusError = StatusCodeValidationError.serverError(500, Data())
        let networkError = NetworkError.httpError(statusError)

        // When
        let mappedError = errorMapper.mapError(networkError)

        // Then
        switch mappedError {
        case let .httpError(error):
            #expect(error.statusCode == 500)
        default:
            Issue.record("NetworkError.httpError는 그대로 반환되어야 함")
        }
    }

    @Test("NetworkError.connectionError 패스스루")
    func passThroughConnectionError() {
        // Given
        let urlError = URLError(.timedOut)
        let networkError = NetworkError.connectionError(urlError)

        // When
        let mappedError = errorMapper.mapError(networkError)

        // Then
        switch mappedError {
        case let .connectionError(error):
            #expect(error.code == .timedOut)
        default:
            Issue.record("NetworkError.connectionError는 그대로 반환되어야 함")
        }
    }

    // MARK: - Error Description Tests

    @Test("NetworkError 에러 설명 확인")
    func validateNetworkErrorDescriptions() {
        // Given
        let statusError = StatusCodeValidationError.clientError(400, Data())
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test")
        )
        let urlError = URLError(.networkConnectionLost)
        let unknownError = NSError(domain: "test", code: 1)

        // When
        let statusMappedError = errorMapper.mapError(statusError)
        let decodingMappedError = errorMapper.mapError(decodingError)
        let urlMappedError = errorMapper.mapError(urlError)
        let unknownMappedError = errorMapper.mapError(unknownError)

        // Then
        #expect(statusMappedError.errorDescription?.contains("HTTP Error") == true)
        #expect(decodingMappedError.errorDescription?.contains("Decoding Error") == true)
        #expect(urlMappedError.errorDescription?.contains("Connection Error") == true)
        #expect(unknownMappedError.errorDescription?.contains("Unknown Error") == true)
    }

    // MARK: - Retryable Check Tests

    @Test("isRetryable 메서드 테스트")
    func validateIsRetryableMethod() {
        // Given
        let retryableError = URLError(.networkConnectionLost)
        let nonRetryableError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test")
        )

        // When & Then
        #expect(errorMapper.isRetryable(retryableError) == true)
        #expect(errorMapper.isRetryable(nonRetryableError) == false)
    }

    @Test("isRetryable - 서버 에러 500번대는 재시도 가능")
    func isRetryableServerErrors() {
        // Given
        let error500 = StatusCodeValidationError.serverError(500, nil)
        let error502 = StatusCodeValidationError.serverError(502, nil)
        let error503 = StatusCodeValidationError.serverError(503, nil)

        // When & Then
        #expect(errorMapper.isRetryable(error500) == true)
        #expect(errorMapper.isRetryable(error502) == true)
        #expect(errorMapper.isRetryable(error503) == true)
    }

    @Test("isRetryable - 클라이언트 에러 400번대는 재시도 불가")
    func isRetryableClientErrors() {
        // Given
        let error400 = StatusCodeValidationError.clientError(400, nil)
        let error401 = StatusCodeValidationError.clientError(401, nil)
        let error404 = StatusCodeValidationError.clientError(404, nil)

        // When & Then
        #expect(errorMapper.isRetryable(error400) == false)
        #expect(errorMapper.isRetryable(error401) == false)
        #expect(errorMapper.isRetryable(error404) == false)
    }

    // MARK: - Preset Tests

    @Test("기본 ErrorMapper 생성")
    func validateDefaultErrorMapperCreation() {
        // Given & When
        let mapper = ErrorMapper.default

        // Then
        #expect(mapper is ErrorMapper)
    }

    @Test("조용한 ErrorMapper 생성")
    func validateSilentErrorMapperCreation() {
        // Given & When
        let mapper = ErrorMapper.silent

        // Then
        #expect(mapper is ErrorMapper)
    }

    @Test("조용한 ErrorMapper 로깅 없이 동작")
    func silentErrorMapperMapsWithoutLogging() {
        // Given
        let urlError = URLError(.notConnectedToInternet)

        // When
        let mappedError = silentErrorMapper.mapError(urlError)

        // Then
        switch mappedError {
        case let .connectionError(error):
            #expect(error.code == .notConnectedToInternet)
        default:
            Issue.record("URLError는 connectionError로 매핑되어야 함")
        }
    }

    // MARK: - Request Context Tests

    @Test("요청 컨텍스트와 함께 에러 매핑")
    func mapErrorWithRequestContext() {
        // Given
        struct TestRequest: APIRequest {
            var baseURL: URL = .init(string: "https://api.example.com")!
            var path: String = "/test"
            var method: HTTPMethod = .get
            var task: HTTPTask = .requestPlain
        }

        let urlError = URLError(.timedOut)
        let request = TestRequest()

        // When
        let mappedError = errorMapper.mapError(urlError, request: request)

        // Then
        switch mappedError {
        case let .connectionError(error):
            #expect(error.code == .timedOut)
        default:
            Issue.record("URLError는 connectionError로 매핑되어야 함")
        }
    }

    @Test("요청 컨텍스트 nil로 에러 매핑")
    func mapErrorWithNilRequestContext() {
        // Given
        let urlError = URLError(.timedOut)

        // When
        let mappedError = errorMapper.mapError(urlError, request: nil)

        // Then
        switch mappedError {
        case let .connectionError(error):
            #expect(error.code == .timedOut)
        default:
            Issue.record("URLError는 connectionError로 매핑되어야 함")
        }
    }
}

// MARK: - NetworkError Tests

struct NetworkErrorTests {
    @Test("NetworkError.httpError errorDescription")
    func httpErrorDescription() {
        // Given
        let statusError = StatusCodeValidationError.clientError(400, nil)
        let error = NetworkError.httpError(statusError)

        // Then
        #expect(error.errorDescription?.contains("HTTP Error") == true)
    }

    @Test("NetworkError.decodingError errorDescription")
    func decodingErrorDescription() {
        // Given
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test")
        )
        let error = NetworkError.decodingError(decodingError)

        // Then
        #expect(error.errorDescription?.contains("Decoding Error") == true)
    }

    @Test("NetworkError.connectionError errorDescription")
    func connectionErrorDescription() {
        // Given
        let urlError = URLError(.notConnectedToInternet)
        let error = NetworkError.connectionError(urlError)

        // Then
        #expect(error.errorDescription?.contains("Connection Error") == true)
    }

    @Test("NetworkError.unknown errorDescription")
    func unknownErrorDescription() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 123)
        let error = NetworkError.unknown(nsError)

        // Then
        #expect(error.errorDescription?.contains("Unknown Error") == true)
    }

    @Test("NetworkError.isRetryable - httpError with 5xx")
    func isRetryableHttpError5xx() {
        // Given
        let statusError = StatusCodeValidationError.serverError(500, nil)
        let error = NetworkError.httpError(statusError)

        // Then
        #expect(error.isRetryable == true)
    }

    @Test("NetworkError.isRetryable - httpError with 4xx")
    func isRetryableHttpError4xx() {
        // Given
        let statusError = StatusCodeValidationError.clientError(400, nil)
        let error = NetworkError.httpError(statusError)

        // Then
        #expect(error.isRetryable == false)
    }

    @Test("NetworkError.isRetryable - connectionError")
    func isRetryableConnectionError() {
        // Given
        let urlError = URLError(.timedOut)
        let error = NetworkError.connectionError(urlError)

        // Then
        #expect(error.isRetryable == true)
    }

    @Test("NetworkError.isRetryable - decodingError")
    func isRetryableDecodingError() {
        // Given
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test")
        )
        let error = NetworkError.decodingError(decodingError)

        // Then
        #expect(error.isRetryable == false)
    }

    @Test("NetworkError.isRetryable - unknown")
    func isRetryableUnknownError() {
        // Given
        let nsError = NSError(domain: "Test", code: 1)
        let error = NetworkError.unknown(nsError)

        // Then
        #expect(error.isRetryable == false)
    }
}

// MARK: - Helper for Tests

private enum CodingKeys: String, CodingKey {
    case name
}
