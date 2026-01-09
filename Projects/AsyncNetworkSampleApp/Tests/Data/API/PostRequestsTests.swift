//
//  PostRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
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
    
    // MARK: - Error Response Models Tests
    
    @Test("PostNotFoundError가 Codable을 준수하는지 확인")
    func testPostNotFoundErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(PostNotFoundError.self, from: data)
        
        // Then
        #expect(error.error == "Post not found")
        #expect(error.code == "POST_NOT_FOUND")
    }
    
    @Test("BadRequestError가 Codable을 준수하는지 확인")
    func testBadRequestErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Bad Request",
          "message": "Invalid request body"
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(BadRequestError.self, from: data)
        
        // Then
        #expect(error.error == "Bad Request")
        #expect(error.message == "Invalid request body")
    }
    
    // MARK: - PostBodyDTO Tests
    
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
