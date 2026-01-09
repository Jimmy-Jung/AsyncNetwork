//
//  SettingsViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
import AsyncViewModel
import Combine
import Foundation

/// Settings 화면 ViewModel
@AsyncViewModel
@MainActor
final class SettingsViewModel {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case viewDidAppear
        case viewDidDisappear
        case configurationPresetSelected(NetworkConfigurationPreset)
        case retryPolicyPresetSelected(RetryPolicyPreset)
        case loggingLevelSelected(LoggingLevel)
        case resetToDefaultsTapped
    }

    enum Action: Equatable, Sendable {
        // Input → Action
        case viewDidAppear
        case viewDidDisappear
        case configurationPresetChanged(NetworkConfigurationPreset)
        case retryPolicyPresetChanged(RetryPolicyPreset)
        case loggingLevelChanged(LoggingLevel)
        case resetToDefaults

        // Effect → Action
        case networkStatusUpdated(NetworkStatus)
        case networkMonitoringStarted
        case networkMonitoringStopped
    }

    struct State: Equatable, Sendable {
        var configurationPreset: NetworkConfigurationPreset = .development
        var retryPolicyPreset: RetryPolicyPreset = .default
        var loggingLevel: LoggingLevel = .verbose
        var networkStatus: NetworkStatus = .connected(.wifi)
        var isExpensive: Bool = false
        var isConstrained: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case networkMonitoring
    }

    // MARK: - Properties

    @Published var state: State
    var timer: any AsyncTimer = SystemTimer()

    private let networkMonitor: any NetworkMonitoring

    // MARK: - Initialization

    init(networkMonitor: any NetworkMonitoring = NetworkMonitor.shared) {
        state = State()
        self.networkMonitor = networkMonitor
    }

    // MARK: - AsyncViewModel Protocol

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear:
            return [.viewDidAppear]
        case .viewDidDisappear:
            return [.viewDidDisappear]
        case let .configurationPresetSelected(preset):
            return [.configurationPresetChanged(preset)]
        case let .retryPolicyPresetSelected(preset):
            return [.retryPolicyPresetChanged(preset)]
        case let .loggingLevelSelected(level):
            return [.loggingLevelChanged(level)]
        case .resetToDefaultsTapped:
            return [.resetToDefaults]
        }
    }

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .viewDidAppear:
            // NetworkMonitor 상태를 즉시 로드
            let status: NetworkStatus = networkMonitor.isConnected
                ? .connected(networkMonitor.connectionType)
                : .disconnected
            state.networkStatus = status
            state.isExpensive = networkMonitor.isExpensive
            state.isConstrained = networkMonitor.isConstrained
            return []

        case .viewDidDisappear:
            return [
                .cancel(id: .networkMonitoring)
            ]

        case let .configurationPresetChanged(preset):
            state.configurationPreset = preset
            return []

        case let .retryPolicyPresetChanged(preset):
            state.retryPolicyPreset = preset
            return []

        case let .loggingLevelChanged(level):
            state.loggingLevel = level
            return []

        case .resetToDefaults:
            state.configurationPreset = .development
            state.retryPolicyPreset = .default
            state.loggingLevel = .verbose
            return []

        case let .networkStatusUpdated(status):
            state.networkStatus = status
            state.isExpensive = networkMonitor.isExpensive
            state.isConstrained = networkMonitor.isConstrained
            return []

        case .networkMonitoringStarted, .networkMonitoringStopped:
            return []
        }
    }

    func handleError(_ error: SendableError) {
        // 에러 로깅 (필요 시 구현)
        print("SettingsViewModel Error: \(error.localizedDescription)")
    }
}
