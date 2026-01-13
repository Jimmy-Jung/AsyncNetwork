//
//  PostRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Added @APITestable MockScenario tests
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncNetwork

@Suite("Post API Requests Tests")
struct PostRequestsTests {
    
    // MARK: - GetAllPostsRequest Tests
    
    @Test("GetAllPostsRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func testGetAllPostsRequestQueryParameters() {
        // Given
        var request = GetAllPostsRequest()
        request.userId = 1
        request.limit = 10
        request.page = 2
        
        // Then
        #expect(request.userId == 1)
        #expect(request.limit == 10)
        #expect(request.page == 2)
    }
    
    @Test("GetAllPostsRequest - Success 시나리오")
    func testGetAllPostsRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetAllPostsRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let posts = try JSONDecoder().decode([PostDTO].self, from: responseData)
        #expect(!posts.isEmpty, "포스트 배열이 비어있지 않아야 함")
    }
    
    @Test("GetAllPostsRequest - ServerError 시나리오")
    func testGetAllPostsRequestServerErrorScenario() throws {
        // Given
        let (data, response, error) = GetAllPostsRequest.mockResponse(for: .serverError)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 500)
        
        let errorData = try #require(data)
        let errorResponse = try JSONDecoder().decode([String: String].self, from: errorData)
        #expect(errorResponse["error"] == "Internal Server Error")
    }
    
    @Test("GetAllPostsRequest - NetworkError 시나리오")
    func testGetAllPostsRequestNetworkErrorScenario() {
        // Given
        let (data, response, error) = GetAllPostsRequest.mockResponse(for: .networkError)
        
        // Then
        #expect(data == nil)
        #expect(response == nil)
        #expect(error != nil, "네트워크 에러가 있어야 함")
    }
    
    @Test("GetAllPostsRequest - Timeout 시나리오")
    func testGetAllPostsRequestTimeoutScenario() {
        // Given
        let (data, response, error) = GetAllPostsRequest.mockResponse(for: .timeout)
        
        // Then
        #expect(data == nil)
        #expect(response == nil)
        #expect(error != nil)
        
        let nsError = error as? NSError
        #expect(nsError?.code == NSURLErrorTimedOut)
    }
    
    // MARK: - GetPostByIdRequest Tests
    
    @Test("GetPostByIdRequest가 동적 경로를 생성하는지 확인")
    func testGetPostByIdRequestPath() {
        // Given
        let request = GetPostByIdRequest(id: 123)
        
        // When
        let path = request.path
        
        // Then
        #expect(path == "/posts/123")
    }
    
    @Test("GetPostByIdRequest - Success 시나리오")
    func testGetPostByIdRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetPostByIdRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let post = try JSONDecoder().decode(PostDTO.self, from: responseData)
        #expect(post.id > 0)
    }
    
    @Test("GetPostByIdRequest - NotFound 시나리오")
    func testGetPostByIdRequestNotFoundScenario() throws {
        // Given
        let (data, response, error) = GetPostByIdRequest.mockResponse(for: .notFound)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)
        
        let errorData = try #require(data)
        let postError = try JSONDecoder().decode(PostNotFoundError.self, from: errorData)
        #expect(postError.code == "POST_NOT_FOUND")
    }
    
    // MARK: - CreatePostRequest Tests
    
    @Test("CreatePostRequest가 Content-Type 헤더를 설정하는지 확인")
    func testCreatePostRequestHeaders() {
        // Given
        let request = CreatePostRequest()
        
        // Then
        #expect(request.contentType == "application/json")
    }
    
    @Test("CreatePostRequest가 RequestBody를 포함하는지 확인")
    func testCreatePostRequestBody() {
        // Given
        let body = PostBodyDTO(title: "Test", body: "Body", userId: 1)
        var request = CreatePostRequest()
        request.body = body
        
        // Then
        #expect(request.body?.title == "Test")
        #expect(request.body?.body == "Body")
        #expect(request.body?.userId == 1)
    }
    
    @Test("CreatePostRequest - Success 시나리오")
    func testCreatePostRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = CreatePostRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let post = try JSONDecoder().decode(PostDTO.self, from: responseData)
        #expect(post.id > 0, "생성된 포스트는 ID를 가져야 함")
    }
    
    @Test("CreatePostRequest - ClientError 시나리오")
    func testCreatePostRequestClientErrorScenario() throws {
        // Given
        let (data, response, error) = CreatePostRequest.mockResponse(for: .clientError)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400)
        
        let errorData = try #require(data)
        let badRequest = try JSONDecoder().decode(BadRequestError.self, from: errorData)
        #expect(badRequest.error == "Bad Request")
    }
    
    @Test("CreatePostRequest - Unauthorized 시나리오")
    func testCreatePostRequestUnauthorizedScenario() throws {
        // Given
        let (_, response, error) = CreatePostRequest.mockResponse(for: .unauthorized)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 401)
    }
    
    // MARK: - UpdatePostRequest Tests
    
    @Test("UpdatePostRequest가 동적 경로를 생성하는지 확인")
    func testUpdatePostRequestPath() {
        // Given
        let request = UpdatePostRequest(id: 456)
        
        // When
        let path = request.path
        
        // Then
        #expect(path == "/posts/456")
    }
    
    @Test("UpdatePostRequest - Success 시나리오")
    func testUpdatePostRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = UpdatePostRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let post = try JSONDecoder().decode(PostDTO.self, from: responseData)
        #expect(post.id > 0)
    }
    
    @Test("UpdatePostRequest - NotFound 시나리오")
    func testUpdatePostRequestNotFoundScenario() throws {
        // Given
        let (_, response, _) = UpdatePostRequest.mockResponse(for: .notFound)
        
        // Then
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)
    }
    
    // MARK: - PatchPostRequest Tests
    
    @Test("PatchPostRequest - Success 시나리오")
    func testPatchPostRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = PatchPostRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let post = try JSONDecoder().decode(PostDTO.self, from: responseData)
        #expect(post.id > 0)
    }
    
    @Test("PatchPostRequest - NotFound 시나리오")
    func testPatchPostRequestNotFoundScenario() throws {
        // Given
        let (_, response, _) = PatchPostRequest.mockResponse(for: .notFound)
        
        // Then
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)
    }
    
    @Test("PatchPostRequest - ClientError 시나리오")
    func testPatchPostRequestClientErrorScenario() throws {
        // Given
        let (_, response, _) = PatchPostRequest.mockResponse(for: .clientError)
        
        // Then
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400)
    }
    
    @Test("PatchPostRequest - ServerError 시나리오")
    func testPatchPostRequestServerErrorScenario() throws {
        // Given
        let (_, response, _) = PatchPostRequest.mockResponse(for: .serverError)
        
        // Then
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 500)
    }
    
    @Test("PatchPostRequest - Timeout 시나리오")
    func testPatchPostRequestTimeoutScenario() throws {
        // Given
        let (data, response, error) = PatchPostRequest.mockResponse(for: .timeout)
        
        // Then
        #expect(data == nil)
        #expect(response == nil)
        #expect(error != nil)
        
        let nsError = try #require(error as? NSError)
        #expect(nsError.code == NSURLErrorTimedOut)
    }
    
    // MARK: - DeletePostRequest Tests
    
    @Test("DeletePostRequest가 올바른 경로를 생성하는지 확인")
    func testDeletePostRequestPath() {
        // Given
        let request = DeletePostRequest(id: 789)
        
        // When
        let path = request.path
        
        // Then
        #expect(path == "/posts/789")
    }
    
    @Test("PostBodyDTO가 Codable을 준수하는지 확인")
    func testPostBodyDTOCodable() throws {
        // Given
        let body = PostBodyDTO(title: "Test", body: "Body", userId: 1)
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostBodyDTO.self, from: data)
        
        // Then
        #expect(decoded.title == body.title)
        #expect(decoded.body == body.body)
        #expect(decoded.userId == body.userId)
    }
}
