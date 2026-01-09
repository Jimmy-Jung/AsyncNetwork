//
//  PostListViewModelTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncViewModel

@Suite("PostListViewModel Tests with AsyncViewModel")
struct PostListViewModelTests {
    
    @Test("ViewModel 초기 상태 확인")
    @MainActor
    func testInitialState() async {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // Then
        #expect(store.state.posts.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        #expect(store.state.selectedUserId == nil)
        
        store.cleanup()
    }
    
    @Test("viewDidAppear 액션으로 posts 로드 성공")
    @MainActor
    func testViewDidAppearSuccess() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && !$0.posts.isEmpty }, timeout: 1.0)
        
        #expect(store.state.posts.count == 10)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        #expect(store.actions.contains(.clearError))
        #expect(store.actions.contains(.loadPosts))
        
        store.cleanup()
    }
    
    @Test("refreshButtonTapped 액션으로 posts 새로고침")
    @MainActor
    func testRefresh() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.refreshButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && !$0.posts.isEmpty }, timeout: 1.0)
        
        #expect(!store.state.posts.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.actions.contains(.loadPosts))
        
        store.cleanup()
    }
    
    @Test("filterByUserButtonTapped 액션으로 특정 사용자 posts 필터링")
    @MainActor
    func testLoadPostsForUser() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        let targetUserId = 1
        
        // When
        store.send(.filterByUserButtonTapped(userId: targetUserId))
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.selectedUserId == targetUserId }, timeout: 1.0)
        
        #expect(store.state.selectedUserId == targetUserId)
        #expect(store.state.posts.allSatisfy { $0.userId == targetUserId })
        #expect(store.state.isLoading == false)
        #expect(store.actions.contains(.loadPostsForUser(userId: targetUserId)))
        
        store.cleanup()
    }
    
    @Test("에러 발생 시 handleError 액션 수신")
    @MainActor
    func testErrorOccurred() async throws {
        // Given
        let mockRepository = FailingPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.error != nil }, timeout: 1.0)
        
        #expect(store.state.error != nil)
        #expect(store.state.isLoading == false)
        
        store.cleanup()
    }
    
    @Test("retryButtonTapped 액션으로 재시도")
    @MainActor
    func testRetry() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(
            initialState: PostListViewModel.State(
                posts: [],
                isLoading: false,
                error: SendableError(MockError.networkError)
            ),
            getPostsUseCase: getPostsUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.retryButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.error == nil && !$0.posts.isEmpty }, timeout: 1.0)
        
        #expect(store.state.error == nil)
        #expect(!store.state.posts.isEmpty)
        #expect(store.state.isLoading == false)
        
        store.cleanup()
    }
    
    @Test("viewDidDisappear 액션으로 cleanup")
    @MainActor
    func testCleanup() async {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidDisappear)
        
        // Then
        #expect(store.actions.contains(.cleanup))
        
        store.cleanup()
    }
    
    @Test("State Equatable 검증")
    func testStateEquatable() {
        // Given
        let state1 = PostListViewModel.State(
            posts: [Post(id: 1, userId: 1, title: "Test", body: "Body")],
            isLoading: false,
            error: nil,
            selectedUserId: nil
        )
        
        let state2 = PostListViewModel.State(
            posts: [Post(id: 1, userId: 1, title: "Test", body: "Body")],
            isLoading: false,
            error: nil,
            selectedUserId: nil
        )
        
        let state3 = PostListViewModel.State(
            posts: [],
            isLoading: true,
            error: nil,
            selectedUserId: 1
        )
        
        // Then
        #expect(state1 == state2)
        #expect(state1 != state3)
    }
    
    @Test("Action Equatable 검증")
    func testActionEquatable() {
        // Given
        let action1 = PostListViewModel.Action.loadPosts
        let action2 = PostListViewModel.Action.loadPosts
        let action3 = PostListViewModel.Action.clearError
        let action4 = PostListViewModel.Action.loadPostsForUser(userId: 1)
        let action5 = PostListViewModel.Action.loadPostsForUser(userId: 1)
        let action6 = PostListViewModel.Action.loadPostsForUser(userId: 2)
        
        // Then
        #expect(action1 == action2)
        #expect(action1 != action3)
        #expect(action4 == action5)
        #expect(action4 != action6)
    }
    
    @Test("CancelID 고유성 검증")
    func testCancelIDUniqueness() {
        // Given
        let cancelID1 = PostListViewModel.CancelID.loadPosts
        let cancelID2 = PostListViewModel.CancelID.loadPosts
        let cancelID3 = PostListViewModel.CancelID.loadPostsForUser(1)
        let cancelID4 = PostListViewModel.CancelID.loadPostsForUser(1)
        let cancelID5 = PostListViewModel.CancelID.loadPostsForUser(2)
        
        // Then
        #expect(cancelID1 == cancelID2)
        #expect(cancelID3 == cancelID4)
        #expect(cancelID3 != cancelID5)
    }
    
    @Test("Action 순서 검증")
    @MainActor
    func testActionSequence() async throws {
        // Given
        let mockRepository = MockPostRepository()
        let getPostsUseCase = GetPostsUseCase(repository: mockRepository)
        let viewModel = PostListViewModel(getPostsUseCase: getPostsUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        try await store.wait(for: { !$0.isLoading && !$0.posts.isEmpty }, timeout: 1.0)
        
        // Then
        let actions = store.actions
        #expect(actions.contains(.clearError))
        #expect(actions.contains(.loadPosts))
        
        // 순서 검증
        if let clearErrorIndex = actions.firstIndex(of: .clearError),
           let loadPostsIndex = actions.firstIndex(of: .loadPosts) {
            #expect(clearErrorIndex < loadPostsIndex)
        }
        
        store.cleanup()
    }
}

// MARK: - Mock Repositories

private actor MockPostRepository: PostRepository {
    
    private var posts: [Post] = []
    
    init() {
        // 10개의 Mock 데이터 생성 (userId 1, 2, 3 순환)
        self.posts = (1...10).map { index in
            Post(
                id: index,
                userId: (index % 3) + 1,
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
