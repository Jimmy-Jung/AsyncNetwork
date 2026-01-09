//
//  UserRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncNetwork

@Suite("User API Requests Tests")
struct UserRequestsTests {
    
    // MARK: - GetAllUsersRequest Tests
    
    @Test("GetAllUsersRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func testGetAllUsersRequestQueryParameters() {
        // Given
        var request = GetAllUsersRequest()
        request.limit = 5
        request.page = 1
        
        // Then
        #expect(request.limit == 5)
        #expect(request.page == 1)
    }
    
    @Test("GetAllUsersRequest가 기본값을 가지는지 확인")
    func testGetAllUsersRequestDefaults() {
        // Given
        let request = GetAllUsersRequest()
        
        // Then
        #expect(request.method == .get)
        #expect(request.path == "/users")
    }
    
    // MARK: - GetUserByIdRequest Tests
    
    @Test("GetUserByIdRequest가 동적 경로를 생성하는지 확인")
    func testGetUserByIdRequestPath() throws {
        // Given
        let request = GetUserByIdRequest(id: 10)
        
        // When
        let urlRequest = try request.asURLRequest()
        
        // Then
        let url = try #require(urlRequest.url)
        #expect(url.path == "/users/10")
    }
    
    @Test("GetUserByIdRequest가 ID를 올바르게 설정하는지 확인")
    func testGetUserByIdRequestId() {
        // Given
        let userId = 42
        let request = GetUserByIdRequest(id: userId)
        
        // Then
        #expect(request.id == userId)
        #expect(request.method == .get)
    }
    
    // MARK: - CreateUserRequest Tests
    
    @Test("CreateUserRequest가 Content-Type 헤더를 설정하는지 확인")
    func testCreateUserRequestHeaders() {
        // Given
        let request = CreateUserRequest()
        
        // Then
        #expect(request.contentType == "application/json")
    }
    
    @Test("CreateUserRequest가 RequestBody를 포함하는지 확인")
    func testCreateUserRequestBody() {
        // Given
        let body = UserBodyDTO(
            name: "Test User",
            username: "testuser",
            email: "test@example.com",
            address: nil,
            phone: nil,
            website: nil,
            company: nil
        )
        var request = CreateUserRequest()
        request.body = body
        
        // Then
        #expect(request.body?.name == "Test User")
        #expect(request.body?.username == "testuser")
        #expect(request.body?.email == "test@example.com")
    }
    
    @Test("CreateUserRequest가 POST 메서드를 사용하는지 확인")
    func testCreateUserRequestMethod() {
        // Given
        let request = CreateUserRequest()
        
        // Then
        #expect(request.method == .post)
        #expect(request.path == "/users")
    }
    
    // MARK: - Error Response Models Tests
    
    @Test("UserNotFoundError가 Codable을 준수하는지 확인")
    func testUserNotFoundErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "User not found",
          "code": "USER_NOT_FOUND"
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(UserNotFoundError.self, from: data)
        
        // Then
        #expect(error.error == "User not found")
        #expect(error.code == "USER_NOT_FOUND")
    }
    
    @Test("UserValidationError가 Codable을 준수하는지 확인")
    func testUserValidationErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Validation Failed",
          "message": "Email format is invalid",
          "fields": ["email"]
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(UserValidationError.self, from: data)
        
        // Then
        #expect(error.error == "Validation Failed")
        #expect(error.message == "Email format is invalid")
        #expect(error.fields?.contains("email") == true)
    }
    
    // MARK: - UserBodyDTO Tests
    
    @Test("UserBodyDTO가 Codable을 준수하는지 확인")
    func testUserBodyDTOCodable() throws {
        // Given
        let body = UserBodyDTO(
            name: "Test",
            username: "test",
            email: "test@example.com",
            address: nil,
            phone: nil,
            website: nil,
            company: nil
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserBodyDTO.self, from: data)
        
        // Then
        #expect(decoded.name == body.name)
        #expect(decoded.username == body.username)
        #expect(decoded.email == body.email)
    }
    
    @Test("UserBodyDTO가 옵셔널 필드를 지원하는지 확인")
    func testUserBodyDTOOptionalFields() throws {
        // Given
        let body = UserBodyDTO(
            name: "Test User",
            username: "testuser",
            email: "test@example.com",
            address: nil,
            phone: "+1234567890",
            website: "https://example.com",
            company: nil
        )
        
        // Then
        #expect(body.phone == "+1234567890")
        #expect(body.website == "https://example.com")
        #expect(body.address == nil)
        #expect(body.company == nil)
    }
}
