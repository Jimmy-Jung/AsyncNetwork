//
//  PostListViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import AsyncViewModel

// MARK: - PostListViewModel

@AsyncViewModel
final class PostListViewModel: ObservableObject {
    
    // MARK: - Input
    
    enum Input: Equatable, Sendable {
        case viewDidAppear
        case refreshButtonTapped
        case retryButtonTapped
        case filterByUserButtonTapped(userId: Int)
        case viewDidDisappear
    }
    
    // MARK: - Action
    
    enum Action: Equatable, Sendable {
        case loadPosts
        case loadPostsForUser(userId: Int)
        case updatePosts([Post])
        case setLoading(Bool)
        case handleError(SendableError)
        case clearError
        case cleanup
    }
    
    // MARK: - State
    
    struct State: Equatable, Sendable {
        var posts: [Post] = []
        var isLoading = false
        var error: SendableError?
        var selectedUserId: Int?
    }
    
    // MARK: - CancelID
    
    enum CancelID: Hashable, Sendable {
        case loadPosts
        case loadPostsForUser(Int)
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Dependencies
    
    private let getPostsUseCase: GetPostsUseCase
    
    // MARK: - Initialization
    
    init(
        initialState: State = State(),
        getPostsUseCase: GetPostsUseCase
    ) {
        self.state = initialState
        self.getPostsUseCase = getPostsUseCase
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear, .refreshButtonTapped, .retryButtonTapped:
            return [.clearError, .loadPosts]
            
        case let .filterByUserButtonTapped(userId):
            return [.clearError, .loadPostsForUser(userId: userId)]
            
        case .viewDidDisappear:
            return [.cleanup]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadPosts:
            state.isLoading = true
            state.error = nil
            state.selectedUserId = nil
            
            return [
                .run(id: .loadPosts) { [getPostsUseCase] in
                    let posts = try await getPostsUseCase.execute()
                    return .updatePosts(posts)
                }
            ]
            
        case let .loadPostsForUser(userId):
            state.isLoading = true
            state.error = nil
            state.selectedUserId = userId
            
            return [
                .run(id: .loadPostsForUser(userId)) { [getPostsUseCase] in
                    let posts = try await getPostsUseCase.execute(for: userId)
                    return .updatePosts(posts)
                }
            ]
            
        case let .updatePosts(posts):
            state.posts = posts
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
            return [
                .cancel(id: .loadPosts),
                .cancel(id: .loadPostsForUser(state.selectedUserId ?? 0))
            ]
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: SendableError) {
        perform(.handleError(error))
    }
}
