//
//  PostDetailViewModelTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncViewModel

// Testing.Comment와 앱의 Comment 충돌 방지
typealias AppComment = AsyncNetworkSampleApp.Comment

@Suite("PostDetailViewModel Tests with AsyncViewModel")
struct PostDetailViewModelTests {
    
    @Test("ViewModel 초기 상태 확인")
    @MainActor
    func testInitialState() async {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let viewModel = PostDetailViewModel(
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // Then
        #expect(store.state.post == nil)
        #expect(store.state.comments.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        
        store.cleanup()
    }
    
    @Test("viewDidAppear 액션으로 post와 comments 로드 성공")
    @MainActor
    func testViewDidAppearSuccess() async throws {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let postId = 1
        let viewModel = PostDetailViewModel(
            postId: postId,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        // 상태가 로딩 완료될 때까지 대기 (isLoading == false && post != nil)
        try await store.wait(for: { !$0.isLoading && $0.post != nil }, timeout: 2.0)
        
        #expect(store.state.post != nil)
        #expect(store.state.post?.id == postId)
        #expect(!store.state.comments.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        #expect(store.actions.contains(.loadPostDetail))
        
        store.cleanup()
    }
    
    @Test("refreshButtonTapped 액션으로 데이터 새로고침")
    @MainActor
    func testRefresh() async throws {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let viewModel = PostDetailViewModel(
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.refreshButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.post != nil }, timeout: 2.0)
        
        #expect(store.state.post != nil)
        #expect(!store.state.comments.isEmpty)
        #expect(store.state.isLoading == false)
        
        store.cleanup()
    }
    
    @Test("Post 로드 실패 시 에러 처리")
    @MainActor
    func testPostLoadFailure() async throws {
        // Given
        let mockPostRepository = FailingPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let viewModel = PostDetailViewModel(
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.error != nil }, timeout: 2.0)
        
        #expect(store.state.post == nil)
        #expect(store.state.error != nil)
        #expect(store.state.isLoading == false)
        
        store.cleanup()
    }
    
    @Test("Comments 로드 실패 시 에러 처리")
    @MainActor
    func testCommentsLoadFailure() async throws {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = FailingCommentRepository()
        let viewModel = PostDetailViewModel(
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.post != nil }, timeout: 2.0)
        
        // Post는 로드되지만 Comments는 실패
        #expect(store.state.post != nil)
        #expect(store.state.comments.isEmpty)
        #expect(store.state.error != nil)
        
        store.cleanup()
    }
    
    @Test("retryButtonTapped 액션으로 재시도")
    @MainActor
    func testRetry() async throws {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let viewModel = PostDetailViewModel(
            initialState: PostDetailViewModel.State(
                post: nil,
                comments: [],
                isLoading: false,
                error: SendableError(MockError.networkError)
            ),
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.retryButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.error == nil && $0.post != nil }, timeout: 2.0)
        
        #expect(store.state.error == nil)
        #expect(store.state.post != nil)
        #expect(!store.state.comments.isEmpty)
        
        store.cleanup()
    }
    
    @Test("viewDidDisappear 액션으로 cleanup")
    @MainActor
    func testCleanup() async {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let viewModel = PostDetailViewModel(
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidDisappear)
        
        // Then
        #expect(store.actions.contains(.cleanup))
        
        store.cleanup()
    }
    
    @Test("concurrent Effect로 Post와 Comments 동시 로드")
    @MainActor
    func testConcurrentLoading() async throws {
        // Given
        let mockPostRepository = MockPostRepository()
        let mockCommentRepository = MockCommentRepository()
        let viewModel = PostDetailViewModel(
            postId: 1,
            postRepository: mockPostRepository,
            commentRepository: mockCommentRepository
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.post != nil && !$0.comments.isEmpty }, timeout: 2.0)
        
        // 두 데이터가 모두 로드되어야 함
        #expect(store.state.post != nil)
        #expect(!store.state.comments.isEmpty)
        
        store.cleanup()
    }
}

// MARK: - Mock Repositories

private actor MockPostRepository: PostRepository {
    func getAllPosts() async throws -> [Post] {
        return []
    }
    
    func getPost(by id: Int) async throws -> Post {
        return Post(
            id: id,
            userId: 1,
            title: "Test Post \(id)",
            body: "Test Body \(id)"
        )
    }
    
    func createPost(_ post: Post) async throws -> Post {
        return post
    }
    
    func updatePost(_ post: Post) async throws -> Post {
        return post
    }
    
    func deletePost(by id: Int) async throws {
        // Success
    }
}

private actor FailingPostRepository: PostRepository {
    func getAllPosts() async throws -> [Post] {
        throw MockError.networkError
    }
    
    func getPost(by id: Int) async throws -> Post {
        throw MockError.networkError
    }
    
    func createPost(_ post: Post) async throws -> Post {
        throw MockError.networkError
    }
    
    func updatePost(_ post: Post) async throws -> Post {
        throw MockError.networkError
    }
    
    func deletePost(by id: Int) async throws {
        throw MockError.networkError
    }
}

private actor MockCommentRepository: CommentRepository {
    func getComments(for postId: Int) async throws -> [AppComment] {
        return (1...3).map { index in
            AppComment(
                id: index,
                postId: postId,
                name: "Comment \(index)",
                email: "user\(index)@example.com",
                body: "Comment body \(index)"
            )
        }
    }
    
    func createComment(_ comment: AppComment) async throws -> AppComment {
        return comment
    }
}

private actor FailingCommentRepository: CommentRepository {
    func getComments(for postId: Int) async throws -> [AppComment] {
        throw MockError.networkError
    }
    
    func createComment(_ comment: AppComment) async throws -> AppComment {
        throw MockError.networkError
    }
}

private enum MockError: Error, LocalizedError {
    case notFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Resource not found"
        case .networkError:
            return "Network error occurred"
        }
    }
}
