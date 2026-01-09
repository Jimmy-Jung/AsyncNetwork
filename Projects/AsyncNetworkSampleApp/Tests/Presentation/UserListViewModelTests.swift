//
//  UserListViewModelTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/07.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp
import AsyncViewModel

@Suite("UserListViewModel Tests with AsyncViewModel")
struct UserListViewModelTests {
    
    @Test("ViewModel 초기 상태 확인")
    @MainActor
    func testInitialState() async {
        // Given
        let mockRepository = MockUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(getUsersUseCase: getUsersUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // Then
        #expect(store.state.users.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        
        store.cleanup()
    }
    
    @Test("viewDidAppear 액션으로 users 로드 성공")
    @MainActor
    func testViewDidAppearSuccess() async throws {
        // Given
        let mockRepository = MockUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(getUsersUseCase: getUsersUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        
        // Then
        try await store.wait(for: { !$0.isLoading && !$0.users.isEmpty }, timeout: 1.0)
        
        #expect(store.state.users.count == 10)
        #expect(store.state.isLoading == false)
        #expect(store.state.error == nil)
        #expect(store.actions.contains(.clearError))
        #expect(store.actions.contains(.loadUsers))
        
        store.cleanup()
    }
    
    @Test("refreshButtonTapped 액션으로 users 새로고침")
    @MainActor
    func testRefresh() async throws {
        // Given
        let mockRepository = MockUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(getUsersUseCase: getUsersUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.refreshButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && !$0.users.isEmpty }, timeout: 1.0)
        
        #expect(!store.state.users.isEmpty)
        #expect(store.state.isLoading == false)
        #expect(store.actions.contains(.loadUsers))
        
        store.cleanup()
    }
    
    @Test("에러 발생 시 handleError 액션 수신")
    @MainActor
    func testErrorOccurred() async throws {
        // Given
        let mockRepository = FailingUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(getUsersUseCase: getUsersUseCase)
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
        let mockRepository = MockUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(
            initialState: UserListViewModel.State(
                users: [],
                isLoading: false,
                error: SendableError(MockError.networkError)
            ),
            getUsersUseCase: getUsersUseCase
        )
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.retryButtonTapped)
        
        // Then
        try await store.wait(for: { !$0.isLoading && $0.error == nil && !$0.users.isEmpty }, timeout: 1.0)
        
        #expect(store.state.error == nil)
        #expect(!store.state.users.isEmpty)
        #expect(store.state.isLoading == false)
        
        store.cleanup()
    }
    
    @Test("viewDidDisappear 액션으로 cleanup")
    @MainActor
    func testCleanup() async {
        // Given
        let mockRepository = MockUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(getUsersUseCase: getUsersUseCase)
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
        let user = User(
            id: 1,
            name: "Test User",
            username: "testuser",
            email: "test@example.com",
            address: Address(
                street: "Test St",
                suite: "Apt 1",
                city: "Test City",
                zipcode: "12345",
                geo: Geo(lat: "0.0", lng: "0.0")
            ),
            phone: "123-456-7890",
            website: "test.com",
            company: Company(
                name: "Test Company",
                catchPhrase: "Test",
                bs: "test"
            )
        )
        
        let state1 = UserListViewModel.State(
            users: [user],
            isLoading: false,
            error: nil
        )
        
        let state2 = UserListViewModel.State(
            users: [user],
            isLoading: false,
            error: nil
        )
        
        let state3 = UserListViewModel.State(
            users: [],
            isLoading: true,
            error: nil
        )
        
        // Then
        #expect(state1 == state2)
        #expect(state1 != state3)
    }
    
    @Test("Action Equatable 검증")
    func testActionEquatable() {
        // Given
        let action1 = UserListViewModel.Action.loadUsers
        let action2 = UserListViewModel.Action.loadUsers
        let action3 = UserListViewModel.Action.clearError
        
        // Then
        #expect(action1 == action2)
        #expect(action1 != action3)
    }
    
    @Test("Action 순서 검증")
    @MainActor
    func testActionSequence() async throws {
        // Given
        let mockRepository = MockUserRepository()
        let getUsersUseCase = GetUsersUseCase(repository: mockRepository)
        let viewModel = UserListViewModel(getUsersUseCase: getUsersUseCase)
        let store = AsyncTestStore(viewModel: viewModel)
        
        // When
        store.send(.viewDidAppear)
        try await store.wait(for: { !$0.isLoading && !$0.users.isEmpty }, timeout: 1.0)
        
        // Then
        let actions = store.actions
        #expect(actions.contains(.clearError))
        #expect(actions.contains(.loadUsers))
        
        // 순서 검증
        if let clearErrorIndex = actions.firstIndex(of: .clearError),
           let loadUsersIndex = actions.firstIndex(of: .loadUsers) {
            #expect(clearErrorIndex < loadUsersIndex)
        }
        
        store.cleanup()
    }
}

// MARK: - Mock Repositories

private actor MockUserRepository: UserRepository {
    
    private var users: [User] = []
    
    init() {
        // 10개의 Mock 데이터 생성
        self.users = (1...10).map { index in
            User(
                id: index,
                name: "User \(index)",
                username: "user\(index)",
                email: "user\(index)@example.com",
                address: Address(
                    street: "Street \(index)",
                    suite: "Suite \(index)",
                    city: "City \(index)",
                    zipcode: "1234\(index)",
                    geo: Geo(lat: "0.0", lng: "0.0")
                ),
                phone: "123-456-789\(index)",
                website: "user\(index).com",
                company: Company(
                    name: "Company \(index)",
                    catchPhrase: "Catch Phrase \(index)",
                    bs: "BS \(index)"
                )
            )
        }
    }
    
    func getAllUsers() async throws -> [User] {
        return users
    }
    
    func getUser(by id: Int) async throws -> User {
        guard let user = users.first(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        return user
    }
    
    func createUser(_ user: User) async throws -> User {
        return user
    }
}

private actor FailingUserRepository: UserRepository {
    func getAllUsers() async throws -> [User] {
        throw MockError.networkError
    }
    
    func getUser(by id: Int) async throws -> User {
        throw MockError.networkError
    }
    
    func createUser(_ user: User) async throws -> User {
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
