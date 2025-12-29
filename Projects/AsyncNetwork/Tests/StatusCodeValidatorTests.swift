//
//  StatusCodeValidatorTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetwork
import Foundation
import Testing

// MARK: - StatusCodeValidatorTests

struct StatusCodeValidatorTests {
    // MARK: - Properties

    private let defaultValidator = StatusCodeValidator()
    private let lenientValidator = StatusCodeValidator.lenient
    private let strictValidator = StatusCodeValidator.strict
    private let customValidator = StatusCodeValidator.custom([200, 201, 202, 204])

    // MARK: - Success Status Code Tests

    @Test("200 상태 코드는 성공으로 검증")
    func validate200StatusCodeAsSuccess() throws {
        // Given
        let response = createMockResponse(statusCode: 200)

        // When
        let validatedResponse = try defaultValidator.validate(response)

        // Then
        #expect(validatedResponse.statusCode == 200)
    }

    @Test("299 상태 코드는 성공으로 검증")
    func validate299StatusCodeAsSuccess() throws {
        // Given
        let response = createMockResponse(statusCode: 299)

        // When
        let validatedResponse = try defaultValidator.validate(response)

        // Then
        #expect(validatedResponse.statusCode == 299)
    }

    @Test("성공 상태 코드 범위 검증", arguments: [200, 201, 204, 250, 299])
    func validateSuccessStatusCodeRange(statusCode: Int) throws {
        // Given
        let response = createMockResponse(statusCode: statusCode)

        // When
        let validatedResponse = try defaultValidator.validate(response)

        // Then
        #expect(validatedResponse.statusCode == statusCode)
    }

    // MARK: - Client Error Tests

    @Test("400 상태 코드는 클라이언트 에러로 처리")
    func validate400StatusCodeAsClientError() {
        // Given
        let response = createMockResponse(statusCode: 400)

        // When & Then
        #expect(throws: StatusCodeValidationError.clientError(400, response.data)) {
            try defaultValidator.validate(response)
        }
    }

    @Test("클라이언트 에러 상태 코드 범위 검증", arguments: [400, 401, 403, 404, 422, 499])
    func validateClientErrorStatusCodeRange(statusCode: Int) {
        // Given
        let response = createMockResponse(statusCode: statusCode)

        // When & Then
        #expect(throws: StatusCodeValidationError.self) {
            try defaultValidator.validate(response)
        }
    }

    // MARK: - Server Error Tests

    @Test("500 상태 코드는 서버 에러로 처리")
    func validate500StatusCodeAsServerError() {
        // Given
        let response = createMockResponse(statusCode: 500)

        // When & Then
        #expect(throws: StatusCodeValidationError.serverError(500, response.data)) {
            try defaultValidator.validate(response)
        }
    }

    @Test("서버 에러 상태 코드 범위 검증", arguments: [500, 502, 503, 504, 599])
    func validateServerErrorStatusCodeRange(statusCode: Int) {
        // Given
        let response = createMockResponse(statusCode: statusCode)

        // When & Then
        #expect(throws: StatusCodeValidationError.self) {
            try defaultValidator.validate(response)
        }
    }

    // MARK: - Invalid Status Code Tests

    @Test("100 상태 코드는 유효하지 않은 상태 코드로 처리")
    func validate100StatusCodeAsInvalid() {
        // Given
        let response = createMockResponse(statusCode: 100)

        // When & Then
        #expect(throws: StatusCodeValidationError.invalidStatusCode(100, response.data)) {
            try defaultValidator.validate(response)
        }
    }

    @Test("유효하지 않은 상태 코드 범위 검증", arguments: [100, 199])
    func validateInvalidStatusCodeRange(statusCode: Int) {
        // Given
        let response = createMockResponse(statusCode: statusCode)

        // When & Then
        #expect(throws: StatusCodeValidationError.self) {
            try defaultValidator.validate(response)
        }
    }

    // MARK: - Unknown Status Code Tests

    @Test("600 상태 코드는 알 수 없는 에러로 처리")
    func validate600StatusCodeAsUnknown() {
        // Given
        let response = createMockResponse(statusCode: 600)

        // When & Then
        #expect(throws: StatusCodeValidationError.unknownError(600, response.data)) {
            try defaultValidator.validate(response)
        }
    }

    // MARK: - Custom Validator Tests

    @Test("관대한 검증자는 300대 상태 코드도 허용")
    func validateLenientValidatorAccepts300Range() throws {
        // Given
        let response = createMockResponse(statusCode: 300)

        // When
        let validatedResponse = try lenientValidator.validate(response)

        // Then
        #expect(validatedResponse.statusCode == 300)
    }

    @Test("관대한 검증자는 399 상태 코드도 허용")
    func validateLenientValidatorAccepts399() throws {
        // Given
        let response = createMockResponse(statusCode: 399)

        // When
        let validatedResponse = try lenientValidator.validate(response)

        // Then
        #expect(validatedResponse.statusCode == 399)
    }

    @Test("엄격한 검증자는 200, 201, 204만 허용")
    func validateStrictValidatorAcceptsOnlySpecificCodes() throws {
        // Given
        let validResponses = [200, 201, 204].map { createMockResponse(statusCode: $0) }
        let invalidResponse = createMockResponse(statusCode: 202)

        // When & Then - 유효한 상태 코드들
        for response in validResponses {
            let validatedResponse = try strictValidator.validate(response)
            #expect(validatedResponse.statusCode == response.statusCode)
        }

        // When & Then - 무효한 상태 코드
        #expect(throws: StatusCodeValidationError.self) {
            try strictValidator.validate(invalidResponse)
        }
    }

    @Test("커스텀 검증자는 지정된 상태 코드만 허용")
    func validateCustomValidatorAcceptsOnlySpecifiedCodes() throws {
        // Given
        let validResponses = [200, 201, 202, 204].map { createMockResponse(statusCode: $0) }
        let invalidResponse = createMockResponse(statusCode: 203)

        // When & Then - 유효한 상태 코드들
        for response in validResponses {
            let validatedResponse = try customValidator.validate(response)
            #expect(validatedResponse.statusCode == response.statusCode)
        }

        // When & Then - 무효한 상태 코드
        #expect(throws: StatusCodeValidationError.self) {
            try customValidator.validate(invalidResponse)
        }
    }

    // MARK: - Helper Method Tests

    @Test("성공 상태 코드 확인 메서드")
    func validateIsSuccessStatusCodeMethod() {
        // Given & When & Then
        #expect(defaultValidator.isSuccessStatusCode(200) == true)
        #expect(defaultValidator.isSuccessStatusCode(299) == true)
        #expect(defaultValidator.isSuccessStatusCode(300) == false)
        #expect(defaultValidator.isSuccessStatusCode(400) == false)
        #expect(defaultValidator.isSuccessStatusCode(500) == false)
    }

    @Test("재시도 가능 상태 코드 확인 메서드")
    func validateIsRetryableStatusCodeMethod() {
        // Given & When & Then
        #expect(defaultValidator.isRetryableStatusCode(500) == true)
        #expect(defaultValidator.isRetryableStatusCode(502) == true)
        #expect(defaultValidator.isRetryableStatusCode(599) == true)
        #expect(defaultValidator.isRetryableStatusCode(200) == false)
        #expect(defaultValidator.isRetryableStatusCode(400) == false)
        #expect(defaultValidator.isRetryableStatusCode(600) == false)
    }

    // MARK: - Error Properties Tests

    @Test("StatusCodeValidationError 속성 검증")
    func validateStatusCodeValidationErrorProperties() {
        // Given
        let testData = Data("test data".utf8)
        let errors: [StatusCodeValidationError] = [
            .invalidStatusCode(100, testData),
            .clientError(400, testData),
            .serverError(500, testData),
            .unknownError(600, testData)
        ]

        // When & Then
        for error in errors {
            #expect(error.statusCode >= 100)
            #expect(error.responseData == testData)
            #expect(error.errorDescription != nil)
        }
    }

    // MARK: - Edge Cases

    @Test("빈 데이터로 상태 코드 검증")
    func validateStatusCodeWithEmptyData() {
        // Given
        let response = createMockResponse(statusCode: 200, data: Data())

        // When & Then
        let validatedResponse = try? defaultValidator.validate(response)
        #expect(validatedResponse != nil)
        #expect(validatedResponse?.data.isEmpty == true)
    }

    @Test("큰 데이터로 상태 코드 검증")
    func validateStatusCodeWithLargeData() {
        // Given
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        let response = createMockResponse(statusCode: 200, data: largeData)

        // When & Then
        let validatedResponse = try? defaultValidator.validate(response)
        #expect(validatedResponse != nil)
        #expect(validatedResponse?.data.count == largeData.count)
    }
}

// MARK: - Helper Methods

private extension StatusCodeValidatorTests {
    /// Mock HTTPResponse 생성
    func createMockResponse(statusCode: Int, data: Data = Data("test".utf8)) -> HTTPResponse {
        let url = URL(string: "https://example.com")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: [:]
        )!

        return HTTPResponse(
            statusCode: statusCode,
            data: data,
            request: URLRequest(url: url),
            response: httpResponse
        )
    }
}
