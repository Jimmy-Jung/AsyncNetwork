//
//  CommentRequestsTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
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
    
    // MARK: - GetCommentByIdRequest Tests
    
    @Test("GetCommentByIdRequest가 동적 경로를 생성하는지 확인")
    func testGetCommentByIdRequestPath() {
        // Given
        let request = GetCommentByIdRequest(
            baseURLString: "https://jsonplaceholder.typicode.com",
            path: "/comments/42",
            method: .get
        )
        
        // When
        let path = request.path
        
        // Then
        #expect(path == "/comments/42")
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
    
    // MARK: - Error Response Models Tests
    
    @Test("CommentNotFoundError가 Codable을 준수하는지 확인")
    func testCommentNotFoundErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Comment not found",
          "code": "COMMENT_NOT_FOUND"
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(CommentNotFoundError.self, from: data)
        
        // Then
        #expect(error.error == "Comment not found")
        #expect(error.code == "COMMENT_NOT_FOUND")
    }
    
    @Test("CommentValidationError가 Codable을 준수하는지 확인")
    func testCommentValidationErrorCodable() throws {
        // Given
        let json = """
        {
          "error": "Validation Failed",
          "message": "Comment body is too long"
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let error = try decoder.decode(CommentValidationError.self, from: data)
        
        // Then
        #expect(error.error == "Validation Failed")
        #expect(error.message == "Comment body is too long")
    }
    
    // MARK: - CommentBodyDTO Tests
    
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
