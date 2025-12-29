//
//  APITesterViewModel.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation
import AsyncNetwork

@AsyncViewModel
final class APITesterViewModel: ObservableObject {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case sendRequest(endpoint: APIEndpoint, parameters: [String: String], body: String?)
        case clearResponse
        case saveState(endpointID: String)
        case restoreState(endpointID: String)
    }

    enum Action: Equatable, Sendable {
        case performRequest(endpoint: APIEndpoint, parameters: [String: String], body: String?)
        case requestCompleted(APITestResult)
        case requestFailed(String)
        case responseCleared
        case stateSaved(endpointID: String)
        case stateRestored(endpointID: String, State?)
    }

    struct State: Equatable, Sendable {
        var isLoading = false
        var statusCode: Int?
        var responseBody: String?
        var responseHeaders: String?
        var errorMessage: String?
    }

    enum CancelID: Hashable, Sendable {
        case request
    }

    // MARK: - Properties

    @Published var state: State

    // MARK: - Cache

    private static var responseCache: [String: State] = [:]

    // MARK: - Dependencies

    private let repository: APITestRepository

    // MARK: - Initialization

    init(repository: APITestRepository) {
        state = State()
        self.repository = repository
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case let .sendRequest(endpoint, parameters, body):
            return [.performRequest(endpoint: endpoint, parameters: parameters, body: body)]
        case .clearResponse:
            return [.responseCleared]
        case let .saveState(endpointID):
            return [.stateSaved(endpointID: endpointID)]
        case let .restoreState(endpointID):
            let cachedState = Self.responseCache[endpointID]
            return [.stateRestored(endpointID: endpointID, cachedState)]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .performRequest(endpoint, parameters, body):
            state.isLoading = true
            state.errorMessage = nil
            return [
                .runCatchingError(
                    id: .request,
                    errorAction: { .requestFailed($0.localizedDescription) },
                    operation: { [repository] in
                    let result = try await repository.executeRequest(
                        endpoint: endpoint,
                        parameters: parameters,
                        body: body
                    )
                    return .requestCompleted(result)
                },
            ]

        case let .requestCompleted(result):
            state.isLoading = false
            state.statusCode = result.statusCode
            state.responseBody = result.body
            state.responseHeaders = result.headers
            return []

        case let .requestFailed(message):
            state.isLoading = false
            state.errorMessage = message
            return []

        case .responseCleared:
            state = State()
            return []

        case let .stateSaved(endpointID):
            Self.responseCache[endpointID] = state
            return []

        case let .stateRestored(_, cachedState):
            if let cachedState {
                state = cachedState
            } else {
                state = State()
            }
            return []
        }
    }

    // MARK: - Error Handling

    func handleError(_ error: SendableError) {
        perform(.requestFailed(error.localizedDescription))
    }
}
