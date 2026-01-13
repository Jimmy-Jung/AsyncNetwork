//
//  APIPlaygroundViewModelTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/11.
//  Updated: 2026/01/12 - Fixed ViewModel name and structure
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import AsyncViewModel
import Testing

@Suite("APIPlaygroundViewModel Tests")
@MainActor
struct APIPlaygroundViewModelTests {
    
    // MARK: - Helper
    
    /// 테스트용 더미 EndpointMetadata 생성
    private func makeDummyEndpoint(id: String = "test") -> EndpointMetadata {
        EndpointMetadata(
            id: id,
            title: "Test Endpoint",
            description: "Test Description",
            method: "GET",
            path: "/test",
            baseURLString: "https://api.example.com",
            headers: [:],
            tags: [],
            parameters: [],
            responseTypeName: "TestResponse"
        )
    }
    
    // MARK: - Tests
    
    @Test("초기 상태 확인")
    func initialState() async throws {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // Then
        #expect(store.state.selectedRequest == nil)
        #expect(store.state.isInitialized == false)
        #expect(store.state.shouldPresentSettings == false)

        store.cleanup()
    }

    @Test("viewDidAppear 시 초기화")
    func testViewDidAppear() async throws {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.viewDidAppear)

        // Then
        #expect(store.actions.contains(.initialize))

        try await store.waitForEffects()

        #expect(store.state.isInitialized == true)

        store.cleanup()
    }

    @Test("API Request 선택")
    func requestSelection() async throws {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        let testEndpoint = makeDummyEndpoint(id: "createPost")

        // When
        store.send(.requestSelected(testEndpoint))

        // Then
        #expect(store.actions.contains(.selectRequest(testEndpoint)))

        try await store.waitForEffects()

        #expect(store.state.selectedRequest == testEndpoint)

        store.cleanup()
    }

    @Test("여러 API Request 순차 선택")
    func multipleRequestSelections() async throws {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        
        let endpoint1 = makeDummyEndpoint(id: "getAllPosts")
        let endpoint2 = makeDummyEndpoint(id: "createPost")
        let endpoint3 = makeDummyEndpoint(id: "deletePost")

        // When
        store.send(.requestSelected(endpoint1))
        try await store.waitForEffects()

        store.send(.requestSelected(endpoint2))
        try await store.waitForEffects()

        store.send(.requestSelected(endpoint3))
        try await store.waitForEffects()

        // Then
        #expect(store.state.selectedRequest == endpoint3, "마지막으로 선택한 endpoint가 저장되어야 함")

        store.cleanup()
    }

    @Test("초기화 후 Request 선택")
    func initializeAndSelectRequest() async throws {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        let testEndpoint = makeDummyEndpoint(id: "updatePost")

        // When
        store.send(.viewDidAppear)
        try await store.waitForEffects()

        store.send(.requestSelected(testEndpoint))
        try await store.waitForEffects()

        // Then
        #expect(store.state.isInitialized == true)
        #expect(store.state.selectedRequest == testEndpoint)

        store.cleanup()
    }
    
    @Test("Settings 버튼 탭")
    func settingsButtonTapped() async throws {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.settingsButtonTapped)

        // Then
        #expect(store.actions.contains(.presentSettings))

        try await store.waitForEffects()

        #expect(store.state.shouldPresentSettings == true)

        store.cleanup()
    }
    
    @Test("Transform - Input에서 Action으로 변환")
    func testTransform() async {
        // Given
        let viewModel = APIPlaygroundViewModel()
        let testEndpoint = makeDummyEndpoint()

        // When/Then
        let viewDidAppearActions = viewModel.transform(.viewDidAppear)
        #expect(viewDidAppearActions == [.initialize])
        
        let requestSelectedActions = viewModel.transform(.requestSelected(testEndpoint))
        #expect(requestSelectedActions == [.selectRequest(testEndpoint)])
        
        let settingsActions = viewModel.transform(.settingsButtonTapped)
        #expect(settingsActions == [.presentSettings])
    }
    
    @Test("Reduce - Action에 따른 State 변경")
    func testReduce() async {
        // Given
        let viewModel = APIPlaygroundViewModel()
        var state = APIPlaygroundViewModel.State()
        let testEndpoint = makeDummyEndpoint()

        // When: initialize
        _ = viewModel.reduce(state: &state, action: .initialize)
        
        // Then
        #expect(state.isInitialized == true)
        
        // When: selectRequest
        _ = viewModel.reduce(state: &state, action: .selectRequest(testEndpoint))
        
        // Then
        #expect(state.selectedRequest == testEndpoint)
        
        // When: presentSettings
        _ = viewModel.reduce(state: &state, action: .presentSettings)
        
        // Then
        #expect(state.shouldPresentSettings == true)
    }
}
