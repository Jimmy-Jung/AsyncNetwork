//
//  APIPlaygroundSwiftViewModelTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/11.
//

@testable import AsyncNetworkSampleApp
import AsyncViewModel
import Testing

@Suite("APIPlaygroundSwiftViewModel Tests")
struct APIPlaygroundSwiftViewModelTests {
    @Test("초기 상태 확인")
    func initialState() async throws {
        // Given
        let viewModel = APIPlaygroundSwiftViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // Then
        #expect(store.state.selectedMethod == nil)
        #expect(store.state.isInitialized == false)

        store.cleanup()
    }

    @Test("viewDidAppear 시 초기화")
    func testViewDidAppear() async throws {
        // Given
        let viewModel = APIPlaygroundSwiftViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.viewDidAppear)

        // Then
        #expect(store.actions.contains(.initialize))

        try await store.waitForEffects()

        #expect(store.state.isInitialized == true)

        store.cleanup()
    }

    @Test("API 메서드 선택")
    func methodSelection() async throws {
        // Given
        let viewModel = APIPlaygroundSwiftViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.methodSelected(.createPost))

        // Then
        #expect(store.actions.contains(.selectMethod(.createPost)))

        try await store.waitForEffects()

        #expect(store.state.selectedMethod == .createPost)

        store.cleanup()
    }

    @Test("여러 API 메서드 순차 선택")
    func multipleMethodSelections() async throws {
        // Given
        let viewModel = APIPlaygroundSwiftViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.methodSelected(.getAllPosts))
        try await store.waitForEffects()

        store.send(.methodSelected(.createPost))
        try await store.waitForEffects()

        store.send(.methodSelected(.deletePost))
        try await store.waitForEffects()

        // Then
        #expect(store.state.selectedMethod == .deletePost)

        store.cleanup()
    }

    @Test("초기화 후 메서드 선택")
    func initializeAndSelectMethod() async throws {
        // Given
        let viewModel = APIPlaygroundSwiftViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.viewDidAppear)
        try await store.waitForEffects()

        store.send(.methodSelected(.updatePost))
        try await store.waitForEffects()

        // Then
        #expect(store.state.isInitialized == true)
        #expect(store.state.selectedMethod == .updatePost)

        store.cleanup()
    }
}
