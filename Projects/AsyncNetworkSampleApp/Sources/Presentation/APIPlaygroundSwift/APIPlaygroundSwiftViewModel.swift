//
//  APIPlaygroundSwiftViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import AsyncViewModel
import Foundation

/// API Playground SwiftUI를 위한 AsyncViewModel
@AsyncViewModel
@MainActor
final class APIPlaygroundSwiftViewModel {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case viewDidAppear
        case requestSelected(EndpointMetadata)
        case settingsButtonTapped
    }

    enum Action: Equatable, Sendable {
        case initialize
        case selectRequest(EndpointMetadata)
        case presentSettings
    }

    struct State: Equatable, Sendable {
        var selectedRequest: EndpointMetadata?
        var isInitialized: Bool = false
        var shouldPresentSettings: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case initialize
    }

    // MARK: - Properties

    @Published var state: State
    var timer: any AsyncTimer = SystemTimer()

    // MARK: - Initialization

    init(initialState: State = State()) {
        state = initialState
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear:
            return [.initialize]
        case let .requestSelected(request):
            return [.selectRequest(request)]
        case .settingsButtonTapped:
            return [.presentSettings]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .initialize:
            state.isInitialized = true
            return [.none]

        case let .selectRequest(request):
            state.selectedRequest = request
            return [.none]

        case .presentSettings:
            state.shouldPresentSettings = true
            return [.none]
        }
    }

    func handleError(_ error: SendableError) {
        // 에러 처리 로직
        print("Error: \(error)")
    }
}
