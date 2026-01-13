//
//  PostTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Testing
@testable import AsyncNetworkSampleApp

@Suite("Post Domain Model Tests")
struct PostTests {
    @Test("Post 모델이 올바르게 생성되는지 확인")
    func testPostCreation() {
        // Given
        let id = 1
        let userId = 10
        let title = "Test Post"
        let body = "This is a test post body"
        
        // When
        let post = Post(
            id: id,
            userId: userId,
            title: title,
            body: body
        )
        
        // Then
        #expect(post.id == id)
        #expect(post.userId == userId)
        #expect(post.title == title)
        #expect(post.body == body)
    }
    
    @Test("Post가 Equatable을 준수하는지 확인")
    func testPostEquatable() {
        // Given
        let post1 = Post(id: 1, userId: 10, title: "Title", body: "Body")
        let post2 = Post(id: 1, userId: 10, title: "Title", body: "Body")
        let post3 = Post(id: 2, userId: 10, title: "Title", body: "Body")
        
        // Then
        #expect(post1 == post2)
        #expect(post1 != post3)
    }
    
    @Test("Post가 Sendable을 준수하는지 확인")
    func testPostSendable() async {
        // Given
        let post = Post(id: 1, userId: 10, title: "Title", body: "Body")
        
        // When & Then (컴파일되면 Sendable 준수)
        await Task {
            #expect(post.id == 1)
        }.value
    }
}

