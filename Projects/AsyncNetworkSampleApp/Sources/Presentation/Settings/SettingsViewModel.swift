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
        case retryPolicyPresetSelected(RetryPolicyPreset)
        case loggingLevelSelected(LoggingLevel)
        case resetToDefaultsTapped

        // ETag Cache
        case refreshETagCacheUsageTapped
        case clearETagCacheTapped
        case invalidateAllETagsTapped
    }

    enum Action: Equatable, Sendable {
        // Input → Action
        case viewDidAppear
        case viewDidDisappear
        case retryPolicyPresetChanged(RetryPolicyPreset)
        case loggingLevelChanged(LoggingLevel)
        case resetToDefaults

        // Effect → Action
        case networkStatusUpdated(NetworkStatus)
        case networkMonitoringStarted
        case networkMonitoringStopped

        // ETag Cache
        case refreshETagCacheUsage
        case etagCacheUsageUpdated(ETagCacheUsage)
        case clearETagCache
        case invalidateAllETags
    }

    struct State: Equatable, Sendable {
        var retryPolicyPreset: RetryPolicyPreset
        var loggingLevel: LoggingLevel = .verbose
        var networkStatus: NetworkStatus = .connected(.wifi)
        var isExpensive: Bool = false
        var isConstrained: Bool = false

        // ETag Cache
        var etagCacheUsage: ETagCacheUsage = .init(currentCount: 0, capacity: 1000)
        var isRefreshingETagCache: Bool = false

        init(retryPolicyPreset: RetryPolicyPreset = .patient) {
            self.retryPolicyPreset = retryPolicyPreset
        }
    }

    enum CancelID: Hashable, Sendable {
        case networkMonitoring
        case etagCacheRefresh
    }

    // MARK: - Properties

    @Published var state: State
    var timer: any AsyncTimer = SystemTimer()

    private let networkMonitor: any NetworkMonitoring

    // MARK: - Initialization

    init(
        networkMonitor: any NetworkMonitoring = NetworkMonitor.shared
    ) {
        // AppDependency에서 현재 Retry Policy Preset 가져오기
        let currentPreset = AppDependency.shared.currentRetryPolicyPreset
        state = State(retryPolicyPreset: currentPreset)
        self.networkMonitor = networkMonitor
    }

    // MARK: - AsyncViewModel Protocol

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear:
            return [.viewDidAppear, .refreshETagCacheUsage]
        case .viewDidDisappear:
            return [.viewDidDisappear]
        case let .retryPolicyPresetSelected(preset):
            return [.retryPolicyPresetChanged(preset)]
        case let .loggingLevelSelected(level):
            return [.loggingLevelChanged(level)]
        case .resetToDefaultsTapped:
            return [.resetToDefaults]
        case .refreshETagCacheUsageTapped:
            return [.refreshETagCacheUsage]
        case .clearETagCacheTapped:
            return [.clearETagCache]
        case .invalidateAllETagsTapped:
            return [.invalidateAllETags]
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
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

        case let .retryPolicyPresetChanged(preset):
            state.retryPolicyPreset = preset
            // AppDependency에 현재 Retry Policy Preset 저장
            AppDependency.shared.currentRetryPolicyPreset = preset
            return []

        case let .loggingLevelChanged(level):
            state.loggingLevel = level
            // 네트워크 로그 레벨 변경
            AppDependency.shared.setNetworkLogLevel(level.networkLogLevel)
            return []

        case .resetToDefaults:
            state.retryPolicyPreset = .patient
            state.loggingLevel = .verbose
            // AppDependency에 기본값 저장
            AppDependency.shared.currentRetryPolicyPreset = .patient
            return []

        case let .networkStatusUpdated(status):
            state.networkStatus = status
            state.isExpensive = networkMonitor.isExpensive
            state.isConstrained = networkMonitor.isConstrained
            return []

        case .networkMonitoringStarted, .networkMonitoringStopped:
            return []

        // MARK: - ETag Cache Actions

        case .refreshETagCacheUsage:
            guard !state.isRefreshingETagCache else { return [] }
            state.isRefreshingETagCache = true

            return [
                .run(id: .etagCacheRefresh) {
                    let etagInterceptor = await AppDependency.shared.etagInterceptor
                    let currentCount = await etagInterceptor.currentStorageCount

                    let usage = ETagCacheUsage(
                        currentCount: currentCount,
                        capacity: 1000
                    )
                    return .etagCacheUsageUpdated(usage)
                }
            ]

        case let .etagCacheUsageUpdated(usage):
            state.isRefreshingETagCache = false
            state.etagCacheUsage = usage
            return []

        case .clearETagCache:
            return [
                .run {
                    await AppDependency.shared.etagInterceptor.invalidateAllETags()
                    return .refreshETagCacheUsage
                }
            ]

        case .invalidateAllETags:
            return [
                .run {
                    await AppDependency.shared.etagInterceptor.invalidateAllETags()
                    print("📦 ✨ ETagInterceptor의 모든 ETag 캐시가 무효화되었습니다.")
                    print("📦 다음 요청 시 서버에서 최신 데이터를 가져옵니다.")
                    return .refreshETagCacheUsage
                }
            ]
        }
    }

    func handleError(_ error: SendableError) {
        // 에러 로깅 (필요 시 구현)
        print("SettingsViewModel Error: \(error.localizedDescription)")
    }
}
