//
//  UseCaseTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Testing
@testable import AsyncNetworkSampleApp

@Suite("GetPostsUseCase Tests")
struct GetPostsUseCaseTests {
    
    @Test("GetPostsUseCase가 모든 포스트를 반환하는지 확인")
    func testGetPostsExecute() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let useCase = GetPostsUseCase(repository: mockRepository)
        
        // When
        let posts = try await useCase.execute()
        
        // Then
        #expect(!posts.isEmpty)
        #expect(posts.count == 10)  // mockArray(count: 10)
    }
    
    @Test("GetPostsUseCase가 특정 사용자의 포스트만 필터링하는지 확인")
    func testGetPostsExecuteForUser() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let useCase = GetPostsUseCase(repository: mockRepository)
        let userId = 1
        
        // When
        let posts = try await useCase.execute(for: userId)
        
        // Then
        #expect(!posts.isEmpty)
        #expect(posts.allSatisfy { $0.userId == userId })
    }
}

@Suite("CreatePostUseCase Tests")
struct CreatePostUseCaseTests {
    
    @Test("CreatePostUseCase가 새 포스트를 생성하는지 확인")
    func testCreatePostExecute() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let useCase = CreatePostUseCase(repository: mockRepository)
        
        // When
        let createdPost = try await useCase.execute(
            title: "Test Title",
            body: "Test Body",
            userId: 1
        )
        
        // Then
        #expect(createdPost.title == "Test Title")
        #expect(createdPost.body == "Test Body")
        #expect(createdPost.userId == 1)
    }
    
    @Test("CreatePostUseCase가 빈 제목을 거부하는지 확인")
    func testCreatePostWithEmptyTitle() async {
        // Given
        let mockRepository = MockPostRepository()
        let useCase = CreatePostUseCase(repository: mockRepository)
        
        // When & Then
        await #expect(throws: ValidationError.self) {
            try await useCase.execute(
                title: "",
                body: "Test Body",
                userId: 1
            )
        }
    }
    
    @Test("CreatePostUseCase가 빈 본문을 거부하는지 확인")
    func testCreatePostWithEmptyBody() async {
        // Given
        let mockRepository = MockPostRepository()
        let useCase = CreatePostUseCase(repository: mockRepository)
        
        // When & Then
        await #expect(throws: ValidationError.self) {
            try await useCase.execute(
                title: "Test Title",
                body: "",
                userId: 1
            )
        }
    }
}

// MARK: - Mock Repository for Use Cases

/// PostRepository의 Mock 구현체
///
/// Actor로 구현되어 thread-safe한 접근을 보장합니다.
private actor MockPostRepository: PostRepository {
    
    private var posts: [Post] = []
    
    init() {
        // Mock 데이터 초기화 - 다양한 사용자 ID로 10개 생성
        self.posts = (1...10).map { index in
            Post(
                id: index,
                userId: (index % 3) + 1,  // userId: 1, 2, 3 순환
                title: "Post \(index)",
                body: "Body \(index)"
            )
        }
    }
    
    func getAllPosts() async throws -> [Post] {
        return posts
    }
    
    func getPost(by id: Int) async throws -> Post {
        guard let post = posts.first(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        return post
    }
    
    func createPost(_ post: Post) async throws -> Post {
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
            throw MockError.notFound
        }
        posts[index] = post
        return post
    }
    
    func deletePost(by id: Int) async throws {
        guard let index = posts.firstIndex(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        posts.remove(at: index)
    }
}

private enum MockError: Error {
    case notFound
}

