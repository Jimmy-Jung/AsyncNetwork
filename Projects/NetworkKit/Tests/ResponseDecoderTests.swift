////
////  ResponseDecoderTests.swift
////  NetworkKit
////
////  Created by AI Assistant on 2025/1/15.
////
//
// import Testing
// import Moya
// @testable import NetworkKit
//
//// MARK: - ResponseDecoderTests
//
// struct ResponseDecoderTests {
//
//    // MARK: - Properties
//
//    private let decoder = ResponseDecoder()
//    private let customDateDecoder = ResponseDecoder.withDateFormat("yyyy-MM-dd HH:mm:ss")
//
//    // MARK: - Test Models
//
//    private struct TestUser: Codable, Equatable {
//        let id: Int
//        let name: String
//        let email: String
//        let isActive: Bool
//    }
//
//    private struct TestResponse: Codable, Equatable {
//        let success: Bool
//        let message: String
//        let data: TestUser
//    }
//
//    private struct TestArrayResponse: Codable, Equatable {
//        let items: [TestUser]
//        let count: Int
//    }
//
//    private struct TestDateResponse: Codable, Equatable {
//        let createdAt: Date
//        let updatedAt: Date
//    }
//
//    // MARK: - Successful Decoding Tests
//
//    @Test("유효한 JSON 객체 디코딩 성공")
//    func decodeValidJSONObjectSuccess() throws {
//        // Given
//        let jsonData = """
//        {
//            "id": 1,
//            "name": "John Doe",
//            "email": "john@example.com",
//            "isActive": true
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let decodedUser = try decoder.decode(response, to: TestUser.self)
//
//        // Then
//        #expect(decodedUser.id == 1)
//        #expect(decodedUser.name == "John Doe")
//        #expect(decodedUser.email == "john@example.com")
//        #expect(decodedUser.isActive == true)
//    }
//
//    @Test("중첩된 JSON 객체 디코딩 성공")
//    func decodeNestedJSONObjectSuccess() throws {
//        // Given
//        let jsonData = """
//        {
//            "success": true,
//            "message": "User created successfully",
//            "data": {
//                "id": 123,
//                "name": "Jane Smith",
//                "email": "jane@example.com",
//                "isActive": false
//            }
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let decodedResponse = try decoder.decode(response, to: TestResponse.self)
//
//        // Then
//        #expect(decodedResponse.success == true)
//        #expect(decodedResponse.message == "User created successfully")
//        #expect(decodedResponse.data.id == 123)
//        #expect(decodedResponse.data.name == "Jane Smith")
//    }
//
//    @Test("JSON 배열 디코딩 성공")
//    func decodeJSONArraySuccess() throws {
//        // Given
//        let jsonData = """
//        {
//            "items": [
//                {"id": 1, "name": "User 1", "email": "user1@example.com", "isActive": true},
//                {"id": 2, "name": "User 2", "email": "user2@example.com", "isActive": false}
//            ],
//            "count": 2
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let decodedResponse = try decoder.decode(response, to: TestArrayResponse.self)
//
//        // Then
//        #expect(decodedResponse.items.count == 2)
//        #expect(decodedResponse.count == 2)
//        #expect(decodedResponse.items[0].name == "User 1")
//        #expect(decodedResponse.items[1].name == "User 2")
//    }
//
//    @Test("빈 응답 디코딩 성공")
//    func decodeEmptyResponseSuccess() throws {
//        // Given
//        let response = createMockResponse(data: Data())
//
//        // When
//        let decodedResponse = try decoder.decode(response, to: EmptyResponseDto.self)
//
//        // Then
//        #expect(decodedResponse.result == "0000")
//        #expect(decodedResponse.msg == "Success")
//    }
//
//    // MARK: - Date Decoding Tests
//
//    @Test("ISO8601 날짜 형식 디코딩 성공")
//    func decodeISO8601DateSuccess() throws {
//        // Given
//        let jsonData = """
//        {
//            "createdAt": "2024-01-15T10:30:00Z",
//            "updatedAt": "2024-01-15T11:45:00Z"
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let decodedResponse = try decoder.decode(response, to: TestDateResponse.self)
//
//        // Then
//        #expect(decodedResponse.createdAt.timeIntervalSince1970 > 0)
//        #expect(decodedResponse.updatedAt.timeIntervalSince1970 > 0)
//    }
//
//    @Test("커스텀 날짜 형식 디코딩 성공")
//    func decodeCustomDateFormatSuccess() throws {
//        // Given
//        let jsonData = """
//        {
//            "createdAt": "2024-01-15 10:30:00",
//            "updatedAt": "2024-01-15 11:45:00"
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let decodedResponse = try customDateDecoder.decode(response, to: TestDateResponse.self)
//
//        // Then
//        #expect(decodedResponse.createdAt.timeIntervalSince1970 > 0)
//        #expect(decodedResponse.updatedAt.timeIntervalSince1970 > 0)
//    }
//
//    // MARK: - Safe Decoding Tests
//
//    @Test("안전한 디코딩 성공 케이스")
//    func safeDecodeSuccessCase() {
//        // Given
//        let jsonData = """
//        {
//            "id": 1,
//            "name": "Test User",
//            "email": "test@example.com",
//            "isActive": true
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let result = decoder.safeDecode(response, to: TestUser.self)
//
//        // Then
//        switch result {
//        case .success(let user):
//            #expect(user.name == "Test User")
//        case .failure:
//            #expect(Bool(false), "디코딩이 성공해야 함")
//        }
//    }
//
//    @Test("안전한 디코딩 실패 케이스")
//    func safeDecodeFailureCase() {
//        // Given
//        let invalidJsonData = """
//        {
//            "id": "invalid_id",
//            "name": "Test User",
//            "email": "test@example.com",
//            "isActive": true
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: invalidJsonData)
//
//        // When
//        let result = decoder.safeDecode(response, to: TestUser.self)
//
//        // Then
//        switch result {
//        case .success:
//            #expect(Bool(false), "디코딩이 실패해야 함")
//        case .failure(let error):
//            #expect(error is DecodingError)
//        }
//    }
//
//    // MARK: - Decoding Error Tests
//
//    @Test("잘못된 JSON 형식으로 디코딩 실패")
//    func decodeInvalidJSONFailure() {
//        // Given
//        let invalidJsonData = """
//        {
//            "id": 1,
//            "name": "Test User",
//            "email": "test@example.com",
//            "isActive": true
//        """.data(using: .utf8)! // 닫는 괄호 누락
//        let response = createMockResponse(data: invalidJsonData)
//
//        // When & Then
//        #expect(throws: DecodingError.self) {
//            try decoder.decode(response, to: TestUser.self)
//        }
//    }
//
//    @Test("필수 필드 누락으로 디코딩 실패")
//    func decodeMissingRequiredFieldFailure() {
//        // Given
//        let incompleteJsonData = """
//        {
//            "id": 1,
//            "name": "Test User"
//        }
//        """.data(using: .utf8)! // email, isActive 필드 누락
//        let response = createMockResponse(data: incompleteJsonData)
//
//        // When & Then
//        #expect(throws: DecodingError.self) {
//            try decoder.decode(response, to: TestUser.self)
//        }
//    }
//
//    @Test("타입 불일치로 디코딩 실패")
//    func decodeTypeMismatchFailure() {
//        // Given
//        let typeMismatchJsonData = """
//        {
//            "id": "not_a_number",
//            "name": "Test User",
//            "email": "test@example.com",
//            "isActive": true
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: typeMismatchJsonData)
//
//        // When & Then
//        #expect(throws: DecodingError.self) {
//            try decoder.decode(response, to: TestUser.self)
//        }
//    }
//
//    @Test("잘못된 날짜 형식으로 디코딩 실패")
//    func decodeInvalidDateFormatFailure() {
//        // Given
//        let invalidDateJsonData = """
//        {
//            "createdAt": "invalid_date",
//            "updatedAt": "2024-01-15T10:30:00Z"
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: invalidDateJsonData)
//
//        // When & Then
//        #expect(throws: DecodingError.self) {
//            try decoder.decode(response, to: TestDateResponse.self)
//        }
//    }
//
//    // MARK: - Edge Cases
//
//    @Test("null 값 처리")
//    func decodeNullValues() throws {
//        // Given
//        let jsonData = """
//        {
//            "id": 1,
//            "name": null,
//            "email": "test@example.com",
//            "isActive": true
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When & Then
//        #expect(throws: DecodingError.self) {
//            try decoder.decode(response, to: TestUser.self)
//        }
//    }
//
//    @Test("빈 문자열 처리")
//    func decodeEmptyString() throws {
//        // Given
//        let jsonData = """
//        {
//            "id": 1,
//            "name": "",
//            "email": "test@example.com",
//            "isActive": true
//        }
//        """.data(using: .utf8)!
//        let response = createMockResponse(data: jsonData)
//
//        // When
//        let decodedUser = try decoder.decode(response, to: TestUser.self)
//
//        // Then
//        #expect(decodedUser.name.isEmpty == true)
//    }
//
//    @Test("큰 JSON 데이터 처리")
//    func decodeLargeJSONData() throws {
//        // Given
//        let largeJsonData = createLargeJSONData()
//        let response = createMockResponse(data: largeJsonData)
//
//        // When
//        let decodedResponse = try decoder.decode(response, to: TestArrayResponse.self)
//
//        // Then
//        #expect(decodedResponse.items.count == 1000)
//        #expect(decodedResponse.count == 1000)
//    }
//
//    // MARK: - Decoder Configuration Tests
//
//    @Test("기본 JSONDecoder 설정 확인")
//    func validateDefaultJSONDecoderConfiguration() {
//        // Given
//        let decoder = ResponseDecoder.defaultJSONDecoder()
//
//        // When & Then
//        #expect(decoder.dateDecodingStrategy == .iso8601)
//    }
//
//    @Test("기본 ResponseDecoder 생성")
//    func validateDefaultResponseDecoderCreation() {
//        // Given & When
//        let decoder = ResponseDecoder.default
//
//        // Then
//        #expect(decoder != nil)
//    }
//
//    @Test("커스텀 날짜 형식 ResponseDecoder 생성")
//    func validateCustomDateFormatResponseDecoderCreation() {
//        // Given & When
//        let decoder = ResponseDecoder.withDateFormat("yyyy-MM-dd")
//
//        // Then
//        #expect(decoder != nil)
//    }
// }
//
//// MARK: - Helper Methods
//
// private extension ResponseDecoderTests {
//    /// Mock Response 생성
//    func createMockResponse(data: Data, statusCode: Int = 200) -> Response {
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
//    /// 큰 JSON 데이터 생성 (성능 테스트용)
//    func createLargeJSONData() -> Data {
//        var items: [[String: Any]] = []
//
//        for i in 1...1000 {
//            items.append([
//                "id": i,
//                "name": "User \(i)",
//                "email": "user\(i)@example.com",
//                "isActive": i % 2 == 0
//            ])
//        }
//
//        let jsonObject: [String: Any] = [
//            "items": items,
//            "count": 1000
//        ]
//
//        return try! JSONSerialization.data(withJSONObject: jsonObject)
//    }
// }
