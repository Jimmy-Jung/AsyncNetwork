//
//  AlbumListViewModelTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncViewModel

@Suite("AlbumListViewModel Tests with AsyncViewModel")
struct AlbumListViewModelTests {
    
    @Test("ViewModel 초기 상태 확인")
    @MainActor
    func testInitialState() async {
        // Given
        let mockRepository = MockAlbumRepository()
        let getAlbumsUseCase = GetAlbumsUseCase(repository: mockRepository)
        let viewModel = AlbumListViewModel(
            userId: 1,
            getAlbumsUseCase: getAlbumsUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // Then
        #expect(store.state.albums.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        
        store.cleanup()
    }
    
    @Test("viewDidAppear 액션으로 albums 로드 성공")
    @MainActor
    func testViewDidAppearSuccess() async throws {
        // Given
        let mockRepository = MockAlbumRepository()
        let getAlbumsUseCase = GetAlbumsUseCase(repository: mockRepository)
        let userId = 1
        let viewModel = AlbumListViewModel(
            userId: userId,
            getAlbumsUseCase: getAlbumsUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && !$0.albums.isEmpty }, timeout: 1.0)
        
        #expect(store.state.albums.count == 10)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        #expect(store.actions.contains(.clearError))
        #expect(store.actions.contains(.loadAlbums))
        
        store.cleanup()
    }
    
    @Test("refreshButtonTapped 액션으로 albums 새로고침")
    @MainActor
    func testRefresh() async throws {
        // Given
        let mockRepository = MockAlbumRepository()
        let getAlbumsUseCase = GetAlbumsUseCase(repository: mockRepository)
        let viewModel = AlbumListViewModel(
            userId: 1,
            getAlbumsUseCase: getAlbumsUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.refreshButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && !$0.albums.isEmpty }, timeout: 1.0)
        
        #expect(!store.state.albums.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.actions.contains(.loadAlbums))
        
        store.cleanup()
    }
    
    @Test("에러 발생 시 handleError 액션 수신")
    @MainActor
    func testErrorOccurred() async throws {
        // Given
        let mockRepository = FailingAlbumRepository()
        let getAlbumsUseCase = GetAlbumsUseCase(repository: mockRepository)
        let viewModel = AlbumListViewModel(
            userId: 1,
            getAlbumsUseCase: getAlbumsUseCase
        )
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
        let mockRepository = MockAlbumRepository()
        let getAlbumsUseCase = GetAlbumsUseCase(repository: mockRepository)
        let viewModel = AlbumListViewModel(
            initialState: AlbumListViewModel.State(
                albums: [],
                isLoading: false,
                error: SendableError(MockError.networkError)
            ),
            userId: 1,
            getAlbumsUseCase: getAlbumsUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.retryButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.error == nil && !$0.albums.isEmpty }, timeout: 1.0)
        
        #expect(store.state.error == nil)
        #expect(!store.state.albums.isEmpty)
        #expect(store.state.isLoading == false)
        
        store.cleanup()
    }
    
    @Test("viewDidDisappear 액션으로 cleanup")
    @MainActor
    func testCleanup() async {
        // Given
        let mockRepository = MockAlbumRepository()
        let getAlbumsUseCase = GetAlbumsUseCase(repository: mockRepository)
        let viewModel = AlbumListViewModel(
            userId: 1,
            getAlbumsUseCase: getAlbumsUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidDisappear)
        
        // Then
        #expect(store.actions.contains(.cleanup))
        
        store.cleanup()
    }
}

// MARK: - Mock Repositories

private actor MockAlbumRepository: AlbumRepository {
    
    private var albums: [Album] = []
    
    init() {
        // 10개의 Mock 데이터 생성
        self.albums = (1...10).map { index in
            Album(
                id: index,
                userId: 1,
                title: "Album \(index)"
            )
        }
    }
    
    func getAlbums(for userId: Int) async throws -> [Album] {
        return albums.filter { $0.userId == userId }
    }
    
    func getPhotos(for albumId: Int) async throws -> [Photo] {
        return (1...5).map { index in
            Photo(
                id: albumId * 100 + index,
                albumId: albumId,
                title: "Photo \(index)",
                url: "https://via.placeholder.com/600/\(index)",
                thumbnailUrl: "https://via.placeholder.com/150/\(index)"
            )
        }
    }
}

private actor FailingAlbumRepository: AlbumRepository {
    func getAlbums(for userId: Int) async throws -> [Album] {
        throw MockError.networkError
    }
    
    func getPhotos(for albumId: Int) async throws -> [Photo] {
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
