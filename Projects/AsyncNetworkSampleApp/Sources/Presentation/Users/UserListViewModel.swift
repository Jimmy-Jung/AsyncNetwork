//
//  UserListViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import AsyncViewModel

// MARK: - UserListViewModel

@AsyncViewModel
final class UserListViewModel: ObservableObject {
    
    // MARK: - Input
    
    enum Input: Equatable, Sendable {
        case viewDidAppear
        case refreshButtonTapped
        case retryButtonTapped
        case viewDidDisappear
    }
    
    // MARK: - Action
    
    enum Action: Equatable, Sendable {
        case loadUsers
        case updateUsers([User])
        case setLoading(Bool)
        case handleError(SendableError)
        case clearError
        case cleanup
    }
    
    // MARK: - State
    
    struct State: Equatable, Sendable {
        var users: [User] = []
        var isLoading = false
        var error: SendableError?
    }
    
    // MARK: - CancelID
    
    enum CancelID: Hashable, Sendable {
        case loadUsers
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Dependencies
    
    private let getUsersUseCase: GetUsersUseCase
    
    // MARK: - Initialization
    
    init(
        initialState: State = State(),
        getUsersUseCase: GetUsersUseCase
    ) {
        self.state = initialState
        self.getUsersUseCase = getUsersUseCase
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear, .refreshButtonTapped, .retryButtonTapped:
            return [.clearError, .loadUsers]
            
        case .viewDidDisappear:
            return [.cleanup]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadUsers:
            state.isLoading = true
            state.error = nil
            
            return [
                .run(id: .loadUsers) { [getUsersUseCase] in
                    let users = try await getUsersUseCase.execute()
                    return .updateUsers(users)
                }
            ]
            
        case let .updateUsers(users):
            state.users = users
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
            return [.cancel(id: .loadUsers)]
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: SendableError) {
        perform(.handleError(error))
    }
}

