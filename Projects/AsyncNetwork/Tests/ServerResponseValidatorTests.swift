////
////  ServerResponseValidatorTests.swift
////  NetworkKit
////
////  Created by AI Assistant on 2025/1/15.
////
//
// import Testing
// @testable import AsyncNetwork
//
//// MARK: - ServerResponseValidatorTests
//
// struct ServerResponseValidatorTests {
//
//    // MARK: - Properties
//
//    private let validator = ServerResponseValidator()
//    private let silentValidator = ServerResponseValidator.silent
//
//    // MARK: - Test Models
//
//    private struct TestUser: Codable, Equatable {
//        let id: Int
//        let name: String
//        let email: String?
//    }
//
//    private struct TestSuccessResponse: ServerResponse, Codable, Equatable {
//        let result: String
//        let msg: String
//        let data: TestUser?
//    }
//
//    private struct TestFailureResponse: ServerResponse, Codable, Equatable {
//        let result: String
//        let msg: String
//        let error: String?
//    }
//
//    private struct NonServerResponse: Codable, Equatable {
//        let status: String
//        let message: String
//    }
//
//    private struct TestQubeAPIRequest: QubeAPIRequest {
//        var domain: QubeDomain = .question
//        var urlPath: String = "/test"
//        var errorMap: [String: String] = [
//            "1001": "Invalid request parameters",
//            "1002": "Authentication failed",
//            "5001": "Internal server error"
//        ]
//
//        var task: Task = .requestPlain
//    }
//
//    // MARK: - Response Type Validation Tests
//
//    @Test("ServerResponse 타입 검증 성공")
//    func validateServerResponseTypeSuccess() throws {
//        // Given
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        try validator.validateResponseType(TestSuccessResponse.self, for: request)
//        // 예외가 발생하지 않으면 성공
//    }
//
//    @Test("ServerResponse가 아닌 타입 검증 실패")
//    func validateNonServerResponseTypeFailure() {
//        // Given
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        #expect(
//            throws: ValidationError.invalidResponseType(
//                expected: "ServerResponse",
//                actual: "NonServerResponse"
//            )
//        ) {
//            try validator.validateResponseType(NonServerResponse.self, for: request)
//        }
//    }
//
//    @Test("다양한 ServerResponse 타입 검증")
//    func validateVariousServerResponseTypes() throws {
//        // Given
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        try validator.validateResponseType(TestSuccessResponse.self, for: request)
//        try validator.validateResponseType(TestFailureResponse.self, for: request)
//        try validator.validateResponseType(EmptyResponseDto.self, for: request)
//    }
//
//    // MARK: - Server Response Validation Tests
//
//    @Test("성공 서버 응답 검증")
//    func validateSuccessfulServerResponse() throws {
//        // Given
//        let successResponse = TestSuccessResponse(
//            result: "0000",
//            msg: "Success",
//            data: TestUser(id: 1, name: "John Doe", email: "john@example.com")
//        )
//        let request = TestQubeAPIRequest()
//
//        // When
//        let validatedResponse = try validator.validateServerResponse(successResponse, for: request)
//
//        // Then
//        #expect(validatedResponse == successResponse)
//        #expect(validatedResponse.isSuccess == true)
//    }
//
//    @Test("실패 서버 응답 검증")
//    func validateFailedServerResponse() {
//        // Given
//        let failureResponse = TestFailureResponse(
//            result: "1001",
//            msg: "Invalid request",
//            error: "Missing required parameter"
//        )
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        #expect(throws: ValidationError.serverResponseFailure) {
//            try validator.validateServerResponse(failureResponse, for: request)
//        }
//    }
//
//    @Test("errorMap이 적용된 실패 응답 검증")
//    func validateFailedResponseWithErrorMap() {
//        // Given
//        let failureResponse = TestFailureResponse(
//            result: "1001",
//            msg: "Server error message",
//            error: nil
//        )
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        do {
//            try validator.validateServerResponse(failureResponse, for: request)
//            #expect(Bool(false), "실패 응답은 예외를 발생시켜야 함")
//        } catch let ValidationError.serverResponseFailure(qubeError) {
//            #expect(qubeError.result == "1001")
//            #expect(qubeError.msg == "Server error message")
//            #expect(qubeError.description == "Invalid request parameters") // errorMap에서 매핑됨
//        } catch {
//            #expect(Bool(false), "ValidationError.serverResponseFailure가 발생해야 함")
//        }
//    }
//
//    @Test("errorMap에 없는 에러 코드 처리")
//    func validateFailedResponseWithUnmappedErrorCode() {
//        // Given
//        let failureResponse = TestFailureResponse(
//            result: "9999",
//            msg: "Unknown error",
//            error: nil
//        )
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        do {
//            try validator.validateServerResponse(failureResponse, for: request)
//            #expect(Bool(false), "실패 응답은 예외를 발생시켜야 함")
//        } catch let ValidationError.serverResponseFailure(qubeError) {
//            #expect(qubeError.result == "9999")
//            #expect(qubeError.msg == "Unknown error")
//            #expect(qubeError.description == "Unknown error") // 서버 메시지 사용
//        } catch {
//            #expect(Bool(false), "ValidationError.serverResponseFailure가 발생해야 함")
//        }
//    }
//
//    @Test("ServerResponse가 아닌 타입은 검증 건너뛰기")
//    func skipValidationForNonServerResponseType() throws {
//        // Given
//        let nonServerResponse = NonServerResponse(
//            status: "ok",
//            message: "Success"
//        )
//        let request = TestQubeAPIRequest()
//
//        // When
//        let validatedResponse = try validator.validateServerResponse(nonServerResponse, for: request)
//
//        // Then
//        #expect(validatedResponse == nonServerResponse)
//    }
//
//    // MARK: - Business Rules Validation Tests
//
//    @Test("필수 필드 검증 성공")
//    func validateRequiredFieldSuccess() throws {
//        // Given
//        let response = TestUser(id: 1, name: "John Doe", email: "john@example.com")
//        let rules = [
//            ValidationRule.requiredField(\.email, fieldName: "email")
//        ]
//
//        // When
//        let validatedResponse = try validator.validateBusinessRules(response, rules: rules)
//
//        // Then
//        #expect(validatedResponse == response)
//    }
//
//    @Test("필수 필드 검증 실패")
//    func validateRequiredFieldFailure() {
//        // Given
//        let response = TestUser(id: 1, name: "John Doe", email: nil)
//        let rules = [
//            ValidationRule.requiredField(\.email, fieldName: "email")
//        ]
//
//        // When & Then
//        #expect(throws: ValidationError.missingRequiredField("email")) {
//            try validator.validateBusinessRules(response, rules: rules)
//        }
//    }
//
//    @Test("필드 범위 검증 성공")
//    func validateFieldRangeSuccess() throws {
//        // Given
//        let response = TestUser(id: 5, name: "John Doe", email: "john@example.com")
//        let rules = [
//            ValidationRule.fieldRange(\.id, fieldName: "id", range: 1...10)
//        ]
//
//        // When
//        let validatedResponse = try validator.validateBusinessRules(response, rules: rules)
//
//        // Then
//        #expect(validatedResponse == response)
//    }
//
//    @Test("필드 범위 검증 실패")
//    func validateFieldRangeFailure() {
//        // Given
//        let response = TestUser(id: 15, name: "John Doe", email: "john@example.com")
//        let rules = [
//            ValidationRule.fieldRange(\.id, fieldName: "id", range: 1...10)
//        ]
//
//        // When & Then
//        #expect(throws: ValidationError.invalidFieldValue(field: "id", value: 15)) {
//            try validator.validateBusinessRules(response, rules: rules)
//        }
//    }
//
//    @Test("복합 비즈니스 규칙 검증")
//    func validateMultipleBusinessRules() throws {
//        // Given
//        let response = TestUser(id: 5, name: "John Doe", email: "john@example.com")
//        let rules = [
//            ValidationRule.requiredField(\.email, fieldName: "email"),
//            ValidationRule.fieldRange(\.id, fieldName: "id", range: 1...10)
//        ]
//
//        // When
//        let validatedResponse = try validator.validateBusinessRules(response, rules: rules)
//
//        // Then
//        #expect(validatedResponse == response)
//    }
//
//    @Test("복합 비즈니스 규칙 검증 실패")
//    func validateMultipleBusinessRulesFailure() {
//        // Given
//        let response = TestUser(id: 5, name: "John Doe", email: nil)
//        let rules = [
//            ValidationRule.requiredField(\.email, fieldName: "email"),
//            ValidationRule.fieldRange(\.id, fieldName: "id", range: 1...10)
//        ]
//
//        // When & Then
//        #expect(throws: ValidationError.missingRequiredField("email")) {
//            try validator.validateBusinessRules(response, rules: rules)
//        }
//    }
//
//    // MARK: - ValidationError Tests
//
//    @Test("ValidationError 에러 설명 확인")
//    func validateValidationErrorDescriptions() {
//        // Given
//        let errors: [ValidationError] = [
//            .invalidResponseType(expected: "ServerResponse", actual: "TestType"),
//            .serverResponseFailure(QubeServerError(result: "1001", msg: "Test error", description: "Test")),
//            .missingRequiredField("testField"),
//            .invalidFieldValue(field: "testField", value: "invalidValue")
//        ]
//
//        // When & Then
//        for error in errors {
//            #expect(error.errorDescription != nil)
//            #expect(error.errorDescription!.count > 0)
//        }
//    }
//
//    // MARK: - Preset Tests
//
//    @Test("기본 검증기 생성")
//    func validateDefaultValidator() {
//        // Given & When
//        let defaultValidator = ServerResponseValidator.default
//
//        // Then
//        #expect(defaultValidator != nil)
//    }
//
//    @Test("조용한 검증기 생성")
//    func validateSilentValidator() {
//        // Given & When
//        let silentValidator = ServerResponseValidator.silent
//
//        // Then
//        #expect(silentValidator != nil)
//    }
//
//    @Test("커스텀 검증기 생성")
//    func validateCustomValidator() {
//        // Given & When
//        let customValidator = ServerResponseValidator(enableLogging: false)
//
//        // Then
//        #expect(customValidator != nil)
//    }
//
//    // MARK: - Edge Cases
//
//    @Test("빈 errorMap으로 실패 응답 처리")
//    func validateFailedResponseWithEmptyErrorMap() {
//        // Given
//        let failureResponse = TestFailureResponse(
//            result: "1001",
//            msg: "Server error",
//            error: nil
//        )
//
//        var request = TestQubeAPIRequest()
//        request.errorMap = [:] // 빈 errorMap
//
//        // When & Then
//        do {
//            try validator.validateServerResponse(failureResponse, for: request)
//            #expect(Bool(false), "실패 응답은 예외를 발생시켜야 함")
//        } catch let ValidationError.serverResponseFailure(qubeError) {
//            #expect(qubeError.result == "1001")
//            #expect(qubeError.msg == "Server error")
//            #expect(qubeError.description == "Server error") // 서버 메시지 사용
//        } catch {
//            #expect(Bool(false), "ValidationError.serverResponseFailure가 발생해야 함")
//        }
//    }
//
//    @Test("빈 결과 코드로 응답 처리")
//    func validateResponseWithEmptyResultCode() throws {
//        // Given
//        let response = TestSuccessResponse(
//            result: "",
//            msg: "Empty result code",
//            data: nil
//        )
//        let request = TestQubeAPIRequest()
//
//        // When & Then
//        // 빈 결과 코드는 실패로 간주됨 (isSuccess는 "0000"만 성공)
//        #expect(throws: ValidationError.serverResponseFailure) {
//            try validator.validateServerResponse(response, for: request)
//        }
//    }
//
//    @Test("nil 데이터로 성공 응답 처리")
//    func validateSuccessResponseWithNilData() throws {
//        // Given
//        let response = TestSuccessResponse(
//            result: "0000",
//            msg: "Success with no data",
//            data: nil
//        )
//        let request = TestQubeAPIRequest()
//
//        // When
//        let validatedResponse = try validator.validateServerResponse(response, for: request)
//
//        // Then
//        #expect(validatedResponse.result == "0000")
//        #expect(validatedResponse.data == nil)
//    }
//
//    @Test("커스텀 검증 규칙 생성")
//    func createCustomValidationRule() throws {
//        // Given
//        let customRule = ValidationRule<TestUser>(description: "Name length validation") { user in
//            if user.name.count < 2 {
//                throw ValidationError.invalidFieldValue(field: "name", value: user.name)
//            }
//        }
//
//        let validUser = TestUser(id: 1, name: "John Doe", email: "john@example.com")
//        let invalidUser = TestUser(id: 2, name: "A", email: "a@example.com")
//
//        // When & Then
//        let validatedUser = try validator.validateBusinessRules(validUser, rules: [customRule])
//        #expect(validatedUser == validUser)
//
//        #expect(throws: ValidationError.invalidFieldValue(field: "name", value: "A")) {
//            try validator.validateBusinessRules(invalidUser, rules: [customRule])
//        }
//    }
// }
