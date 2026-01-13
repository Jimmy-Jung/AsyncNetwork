//
//  PostRepositoryTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Testing
@testable import AsyncNetworkSampleApp

@Suite("PostRepository Protocol Tests")
struct PostRepositoryTests {
    
    @Test("getAllPosts가 Post 배열을 반환하는지 확인")
    func testGetAllPosts() async throws {
        // Given
        let repository = MockPostRepository()
        
        // When
        let posts = try await repository.getAllPosts()
        
        // Then
        #expect(!posts.isEmpty)
        #expect(posts.count == 2)
        #expect(posts[0].title == "Mock Post 1")
    }
    
    @Test("getPost가 특정 Post를 반환하는지 확인")
    func testGetPostById() async throws {
        // Given
        let repository = MockPostRepository()
        let postId = 1
        
        // When
        let post = try await repository.getPost(by: postId)
        
        // Then
        #expect(post.id == postId)
        #expect(post.title == "Mock Post 1")
    }
    
    @Test("createPost가 새 Post를 생성하는지 확인")
    func testCreatePost() async throws {
        // Given
        let repository = MockPostRepository()
        let newPost = Post(
            id: 0,
            userId: 1,
            title: "New Post",
            body: "New Body"
        )
        
        // When
        let createdPost = try await repository.createPost(newPost)
        
        // Then
        #expect(createdPost.id == 3) // Mock은 id 3을 반환
        #expect(createdPost.title == newPost.title)
        #expect(createdPost.body == newPost.body)
    }
    
    @Test("updatePost가 Post를 업데이트하는지 확인")
    func testUpdatePost() async throws {
        // Given
        let repository = MockPostRepository()
        let updatedPost = Post(
            id: 1,
            userId: 1,
            title: "Updated Title",
            body: "Updated Body"
        )
        
        // When
        let result = try await repository.updatePost(updatedPost)
        
        // Then
        #expect(result.id == updatedPost.id)
        #expect(result.title == updatedPost.title)
        #expect(result.body == updatedPost.body)
    }
    
    @Test("deletePost가 Post를 삭제하는지 확인")
    func testDeletePost() async throws {
        // Given
        let repository = MockPostRepository()
        let postId = 1
        
        // When & Then (에러가 발생하지 않으면 성공)
        try await repository.deletePost(by: postId)
    }
}

// MARK: - Mock Repository

/// PostRepository의 Mock 구현체
///
/// 실제 네트워크 호출 없이 테스트를 위한 Mock 데이터를 반환합니다.
/// Actor로 구현되어 thread-safe한 접근을 보장합니다.
private actor MockPostRepository: PostRepository {
    
    private var posts: [Post] = [
        Post(id: 1, userId: 1, title: "Mock Post 1", body: "Body 1"),
        Post(id: 2, userId: 1, title: "Mock Post 2", body: "Body 2")
    ]
    
    func getAllPosts() async throws -> [Post] {
        return posts
    }
    
    func getPost(by id: Int) async throws -> Post {
        guard let post = posts.first(where: { $0.id == id }) else {
            throw MockRepositoryError.notFound
        }
        return post
    }
    
    func createPost(_ post: Post) async throws -> Post {
        // 새 ID 할당
        let newId = (posts.map { $0.id }.max() ?? 0) + 1
        let createdPost = Post(
            id: newId,
            userId: post.userId,
            title: post.title,
            body: post.body
        )
        posts.append(createdPost)
        return createdPost
    }
    
    func updatePost(_ post: Post) async throws -> Post {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
            throw MockRepositoryError.notFound
        }
        posts[index] = post
        return post
    }
    
    func deletePost(by id: Int) async throws {
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw MockRepositoryError.notFound
        }
        posts.remove(at: index)
    }
}

private enum MockRepositoryError: Error {
    case notFound
}

