//
//  AlbumListViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import AsyncViewModel

// MARK: - AlbumListViewModel

@AsyncViewModel
final class AlbumListViewModel: ObservableObject {
    
    // MARK: - Input
    
    enum Input: Equatable, Sendable {
        case viewDidAppear
        case refreshButtonTapped
        case retryButtonTapped
        case viewDidDisappear
    }
    
    // MARK: - Action
    
    enum Action: Equatable, Sendable {
        case loadAlbums
        case updateAlbums([Album])
        case setLoading(Bool)
        case handleError(SendableError)
        case clearError
        case cleanup
    }
    
    // MARK: - State
    
    struct State: Equatable, Sendable {
        var albums: [Album] = []
        var isLoading = false
        var error: SendableError?
    }
    
    // MARK: - CancelID
    
    enum CancelID: Hashable, Sendable {
        case loadAlbums
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Dependencies
    
    private let userId: Int
    private let getAlbumsUseCase: GetAlbumsUseCase
    
    // MARK: - Initialization
    
    init(
        initialState: State = State(),
        userId: Int,
        getAlbumsUseCase: GetAlbumsUseCase
    ) {
        self.state = initialState
        self.userId = userId
        self.getAlbumsUseCase = getAlbumsUseCase
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear, .refreshButtonTapped, .retryButtonTapped:
            return [.clearError, .loadAlbums]
            
        case .viewDidDisappear:
            return [.cleanup]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadAlbums:
            state.isLoading = true
            state.error = nil
            
            return [
                .run(id: .loadAlbums) { [getAlbumsUseCase, userId] in
                    let albums = try await getAlbumsUseCase.execute(for: userId)
                    return .updateAlbums(albums)
                }
            ]
            
        case let .updateAlbums(albums):
            state.albums = albums
            state.isLoading = false
            return [.none]
            
        case let .setLoading(isLoading):
            state.isLoading = isLoading
            return [.none]
            
        case let .handleError(error):
            state.error = error
            state.isLoading = false
            return [.none]
            
        case .clearError:
            state.error = nil
            return [.none]
            
        case .cleanup:
            return [.cancel(id: .loadAlbums)]
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: SendableError) {
        perform(.handleError(error))
    }
}

