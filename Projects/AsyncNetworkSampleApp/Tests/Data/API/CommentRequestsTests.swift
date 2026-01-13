//
//  CommentRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Added @APITestable MockScenario tests
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncNetwork

@Suite("Comment API Requests Tests")
struct CommentRequestsTests {
    
    // MARK: - GetCommentsForPostRequest Tests
    
    @Test("GetCommentsForPostRequest가 쿼리 파라미터를 올바르게 설정하는지 확인")
    func testGetCommentsForPostRequestQueryParameters() {
        // Given
        var request = GetCommentsForPostRequest()
        request.postId = 5
        request.limit = 20
        
        // Then
        #expect(request.postId == 5)
        #expect(request.limit == 20)
    }
    
    @Test("GetCommentsForPostRequest - Success 시나리오")
    func testGetCommentsForPostRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetCommentsForPostRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let comments = try JSONDecoder().decode([CommentDTO].self, from: responseData)
        #expect(!comments.isEmpty, "댓글 배열이 비어있지 않아야 함")
    }
    
    @Test("GetCommentsForPostRequest - ClientError 시나리오")
    func testGetCommentsForPostRequestClientErrorScenario() throws {
        // Given
        let (_, response, error) = GetCommentsForPostRequest.mockResponse(for: .clientError)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400)
    }
    
    @Test("GetCommentsForPostRequest - ServerError 시나리오")
    func testGetCommentsForPostRequestServerErrorScenario() throws {
        // Given
        let (_, response, error) = GetCommentsForPostRequest.mockResponse(for: .serverError)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 500)
    }
    
    // MARK: - GetCommentByIdRequest Tests
    
    @Test("GetCommentByIdRequest가 동적 경로를 생성하는지 확인")
    func testGetCommentByIdRequestPath() {
        // Given
        let request = GetCommentByIdRequest(id: 42)
        
        // When
        let path = request.path
        
        // Then
        #expect(path == "/comments/42")
    }
    
    @Test("GetCommentByIdRequest - Success 시나리오")
    func testGetCommentByIdRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = GetCommentByIdRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let comment = try JSONDecoder().decode(CommentDTO.self, from: responseData)
        #expect(comment.id > 0)
    }
    
    @Test("GetCommentByIdRequest - NotFound 시나리오")
    func testGetCommentByIdRequestNotFoundScenario() throws {
        // Given
        let (data, response, error) = GetCommentByIdRequest.mockResponse(for: .notFound)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)
        
        let errorData = try #require(data)
        let commentError = try JSONDecoder().decode(CommentNotFoundError.self, from: errorData)
        #expect(commentError.code == "COMMENT_NOT_FOUND")
    }
    
    // MARK: - CreateCommentRequest Tests
    
    @Test("CreateCommentRequest가 Content-Type 헤더를 설정하는지 확인")
    func testCreateCommentRequestHeaders() {
        // Given
        let request = CreateCommentRequest()
        
        // Then
        #expect(request.contentType == "application/json")
    }
    
    @Test("CreateCommentRequest가 RequestBody를 포함하는지 확인")
    func testCreateCommentRequestBody() {
        // Given
        let body = CommentBodyDTO(
            postId: 1,
            name: "Commenter",
            email: "commenter@example.com",
            body: "Great post!"
        )
        var request = CreateCommentRequest()
        request.body = body
        
        // Then
        #expect(request.body?.postId == 1)
        #expect(request.body?.name == "Commenter")
        #expect(request.body?.email == "commenter@example.com")
        #expect(request.body?.body == "Great post!")
    }
    
    @Test("CreateCommentRequest - Success 시나리오")
    func testCreateCommentRequestSuccessScenario() throws {
        // Given
        let (data, response, error) = CreateCommentRequest.mockResponse(for: .success)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        
        let responseData = try #require(data)
        let comment = try JSONDecoder().decode(CommentDTO.self, from: responseData)
        #expect(comment.id > 0, "생성된 댓글은 ID를 가져야 함")
    }
    
    @Test("CreateCommentRequest - ClientError 시나리오")
    func testCreateCommentRequestClientErrorScenario() throws {
        // Given
        let (data, response, error) = CreateCommentRequest.mockResponse(for: .clientError)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 400)
        
        let errorData = try #require(data)
        let validationError = try JSONDecoder().decode(CommentValidationError.self, from: errorData)
        #expect(validationError.error == "Validation Failed")
    }
    
    @Test("CreateCommentRequest - NotFound 시나리오")
    func testCreateCommentRequestNotFoundScenario() throws {
        // Given
        let (_, response, error) = CreateCommentRequest.mockResponse(for: .notFound)
        
        // Then
        #expect(error == nil)
        
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 404)
    }
    
    @Test("CommentBodyDTO가 Codable을 준수하는지 확인")
    func testCommentBodyDTOCodable() throws {
        // Given
        let body = CommentBodyDTO(
            postId: 1,
            name: "Test",
            email: "test@example.com",
            body: "Comment"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CommentBodyDTO.self, from: data)
        
        // Then
        #expect(decoded.postId == body.postId)
        #expect(decoded.name == body.name)
        #expect(decoded.email == body.email)
        #expect(decoded.body == body.body)
    }
}
