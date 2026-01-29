//
//  UserRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Added @APITestable MockScenario tests
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

    @Test("GetAllUsersRequest - Success 시나리오")
    func testGetAllUsersRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetAllUsersRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let users = try JSONDecoder().decode([UserDTO].self, from: responseData)
        #expect(!users.isEmpty, "사용자 배열이 비어있지 않아야 함")
    }

    @Test("GetAllUsersRequest - ServerError 시나리오")
    func testGetAllUsersRequestServerErrorScenario() throws {
        // Given
        let (_, response, error) = GetAllUsersRequest.mockResponse(for: .serverError)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 500)
    }

    @Test("GetAllUsersRequest - Timeout 시나리오")
    func testGetAllUsersRequestTimeoutScenario() {
        // Given
        let (data, response, error) = GetAllUsersRequest.mockResponse(for: .timeout)

        // Then
        #expect(data == nil)
        #expect(response == nil)
        #expect(error != nil)

        let nsError = error as? NSError
        #expect(nsError?.code == NSURLErrorTimedOut)
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

    @Test("GetUserByIdRequest - Success 시나리오")
    func testGetUserByIdRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetUserByIdRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let user = try JSONDecoder().decode(UserDTO.self, from: responseData)
        #expect(user.id > 0)
    }

    @Test("GetUserByIdRequest - NotFound 시나리오")
    func testGetUserByIdRequestNotFoundScenario() throws {
        // Given
        let (data, response, error) = GetUserByIdRequest.mockResponse(for: .notFound)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)

        let errorData = try #require(data)
        let userError = try JSONDecoder().decode(UserNotFoundError.self, from: errorData)
        #expect(userError.code == "USER_NOT_FOUND")
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

    @Test("CreateUserRequest - Success 시나리오")
    func testCreateUserRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = CreateUserRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let user = try JSONDecoder().decode(UserDTO.self, from: responseData)
        #expect(user.id > 0, "생성된 사용자는 ID를 가져야 함")
    }

    @Test("CreateUserRequest - ClientError 시나리오")
    func testCreateUserRequestClientErrorScenario() throws {
        // Given
        let (data, response, error) = CreateUserRequest.mockResponse(for: .clientError)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400)

        let errorData = try #require(data)
        let validationError = try JSONDecoder().decode(UserValidationError.self, from: errorData)
        #expect(validationError.error == "Validation Failed")
    }

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
}
