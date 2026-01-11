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
        
        // Interceptor
        case interceptorToggled(InterceptorType)
        case testInterceptorsTapped
        case clearInterceptorLogsTapped
        
        // Retry & Error Simulation
        case errorTypeSelected(ErrorType)
        case simulationFailureRateChanged(Double)
        case startErrorSimulationTapped
        case clearSimulationTimelinesTapped
        
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
        
        // Interceptor
        case toggleInterceptor(InterceptorType)
        case executeInterceptorTest
        case clearInterceptorLogs
        case interceptorTestCompleted(InterceptorTestResult)
        case interceptorTestFailed(String)
        
        // Retry & Error Simulation
        case errorTypeChanged(ErrorType)
        case simulationFailureRateUpdated(Double)
        case startErrorSimulation
        case clearSimulationTimelines
        case simulationCompleted(ErrorSimulationTimeline)
        
        // ETag Cache
        case refreshETagCacheUsage
        case etagCacheUsageUpdated(ETagCacheUsage)
        case clearETagCache
        case invalidateAllETags
    }

    struct State: Equatable, Sendable {
        var retryPolicyPreset: RetryPolicyPreset = .standard
        var loggingLevel: LoggingLevel = .verbose
        var networkStatus: NetworkStatus = .connected(.wifi)
        var isExpensive: Bool = false
        var isConstrained: Bool = false
        
        // Interceptor
        var interceptorConfig: InterceptorConfig = InterceptorConfig()
        var isExecutingInterceptorTest: Bool = false
        var interceptorTestResults: [InterceptorTestResult] = []
        var interceptorErrorMessage: String?
        
        // Retry & Error Simulation
        var errorSimulation: ErrorSimulation = ErrorSimulation()
        var isRunningSimulation: Bool = false
        var currentSimulationTimeline: ErrorSimulationTimeline?
        var pastSimulationTimelines: [ErrorSimulationTimeline] = []
        
        // ETag Cache
        var etagCacheUsage: ETagCacheUsage = ETagCacheUsage(currentCount: 0, capacity: 1000)
        var isRefreshingETagCache: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case networkMonitoring
        case interceptorTest
        case errorSimulation
        case etagCacheRefresh
    }

    // MARK: - Properties

    @Published var state: State
    var timer: any AsyncTimer = SystemTimer()

    private let networkMonitor: any NetworkMonitoring
    private let getPostsUseCase: GetPostsUseCase

    // MARK: - Initialization

    init(
        networkMonitor: any NetworkMonitoring = NetworkMonitor.shared,
        getPostsUseCase: GetPostsUseCase? = nil
    ) {
        state = State()
        self.networkMonitor = networkMonitor
        self.getPostsUseCase = getPostsUseCase ?? AppDependency.shared.getPostsUseCase
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
        case let .interceptorToggled(type):
            return [.toggleInterceptor(type)]
        case .testInterceptorsTapped:
            return [.executeInterceptorTest]
        case .clearInterceptorLogsTapped:
            return [.clearInterceptorLogs]
        case let .errorTypeSelected(type):
            return [.errorTypeChanged(type)]
        case let .simulationFailureRateChanged(rate):
            return [.simulationFailureRateUpdated(rate)]
        case .startErrorSimulationTapped:
            return [.startErrorSimulation]
        case .clearSimulationTimelinesTapped:
            return [.clearSimulationTimelines]
        case .refreshETagCacheUsageTapped:
            return [.refreshETagCacheUsage]
        case .clearETagCacheTapped:
            return [.clearETagCache]
        case .invalidateAllETagsTapped:
            return [.invalidateAllETags]
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
                .cancel(id: .networkMonitoring),
                .cancel(id: .interceptorTest),
                .cancel(id: .errorSimulation)
            ]

        case let .retryPolicyPresetChanged(preset):
            state.retryPolicyPreset = preset
            // ErrorSimulation의 재시도 정책도 동기화
            state.errorSimulation.retryPreset = preset
            state.errorSimulation.maxRetries = preset.maxRetries
            state.errorSimulation.baseDelay = preset.baseDelay
            return []

        case let .loggingLevelChanged(level):
            state.loggingLevel = level
            // 네트워크 로그 레벨 변경
            AppDependency.shared.setNetworkLogLevel(level.networkLogLevel)
            return []

        case .resetToDefaults:
            state.retryPolicyPreset = .standard
            state.loggingLevel = .verbose
            state.interceptorConfig = InterceptorConfig()
            state.interceptorTestResults = []
            state.errorSimulation = ErrorSimulation()
            state.pastSimulationTimelines = []
            return []

        case let .networkStatusUpdated(status):
            state.networkStatus = status
            state.isExpensive = networkMonitor.isExpensive
            state.isConstrained = networkMonitor.isConstrained
            return []

        case .networkMonitoringStarted, .networkMonitoringStopped:
            return []
            
        // MARK: - Interceptor Actions
        
        case let .toggleInterceptor(type):
            state.interceptorConfig.toggle(type)
            state.interceptorErrorMessage = nil
            return []
            
        case .executeInterceptorTest:
            guard !state.isExecutingInterceptorTest else { return [] }
            state.isExecutingInterceptorTest = true
            state.interceptorErrorMessage = nil
            
            return [
                .run(id: .interceptorTest) { [config = state.interceptorConfig] in
                    await self.executeInterceptorTest(with: config)
                }
            ]
            
        case .clearInterceptorLogs:
            state.interceptorTestResults = []
            state.interceptorErrorMessage = nil
            return []
            
        case let .interceptorTestCompleted(result):
            state.isExecutingInterceptorTest = false
            state.interceptorTestResults.insert(result, at: 0)
            return []
            
        case let .interceptorTestFailed(message):
            state.isExecutingInterceptorTest = false
            state.interceptorErrorMessage = message
            return []
            
        // MARK: - Error Simulation Actions
        
        case let .errorTypeChanged(type):
            state.errorSimulation.errorType = type
            return []
            
        case let .simulationFailureRateUpdated(rate):
            state.errorSimulation.failureRate = rate
            return []
            
        case .startErrorSimulation:
            guard !state.isRunningSimulation else { return [] }
            state.isRunningSimulation = true
            let simulation = state.errorSimulation
            
            return [
                .run(id: .errorSimulation) {
                    await self.executeErrorSimulation(with: simulation)
                }
            ]
            
        case let .simulationCompleted(timeline):
            state.isRunningSimulation = false
            state.currentSimulationTimeline = timeline
            state.pastSimulationTimelines.insert(timeline, at: 0)
            
            if state.pastSimulationTimelines.count > 20 {
                state.pastSimulationTimelines = Array(state.pastSimulationTimelines.prefix(20))
            }
            return []
            
        case .clearSimulationTimelines:
            state.pastSimulationTimelines = []
            state.currentSimulationTimeline = nil
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
        state.isExecutingInterceptorTest = false
        state.isRunningSimulation = false
    }
    
    // MARK: - Private Methods
    
    private func executeInterceptorTest(with config: InterceptorConfig) async -> Action {
        let startTime = Date()
        var logs: [InterceptorLog] = []
        
        for interceptor in config.activeInterceptors {
            let log = InterceptorLog(
                interceptorType: interceptor,
                action: "요청 수정",
                details: generateInterceptorDetails(interceptor)
            )
            logs.append(log)
        }
        
        do {
            _ = try await getPostsUseCase.execute()
            
            for interceptor in config.activeInterceptors.reversed() {
                let log = InterceptorLog(
                    interceptorType: interceptor,
                    action: "응답 처리",
                    details: "응답 데이터 처리 완료"
                )
                logs.append(log)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let result = InterceptorTestResult(
                success: true,
                requestURL: "https://jsonplaceholder.typicode.com/posts",
                statusCode: 200,
                duration: duration,
                logs: logs
            )
            
            return .interceptorTestCompleted(result)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let result = InterceptorTestResult(
                success: false,
                requestURL: "https://jsonplaceholder.typicode.com/posts",
                statusCode: nil,
                duration: duration,
                logs: logs
            )
            
            return .interceptorTestCompleted(result)
        }
    }
    
    private func generateInterceptorDetails(_ type: InterceptorType) -> String {
        switch type {
        case .consoleLogging:
            return "요청 정보를 콘솔에 출력"
        case .auth:
            return "Authorization: Bearer <token> 추가"
        case .customHeader:
            return "X-Custom-Header: AsyncNetwork-Demo 추가"
        case .timestamp:
            return "X-Timestamp: \(Date().timeIntervalSince1970) 추가"
        }
    }
    
    private func executeErrorSimulation(with simulation: ErrorSimulation) async -> Action {
        var timeline = ErrorSimulationTimeline(simulation: simulation)
        var attemptNumber = 1
        var success = false
        
        let firstShouldFail = simulation.shouldFail()
        
        if firstShouldFail {
            let attempt = ErrorSimulationAttempt(
                attemptNumber: attemptNumber,
                success: false,
                error: simulation.errorType.description,
                errorType: simulation.errorType,
                delay: nil
            )
            timeline.addAttempt(attempt)
        } else {
            do {
                _ = try await getPostsUseCase.execute()
                let attempt = ErrorSimulationAttempt(
                    attemptNumber: attemptNumber,
                    success: true,
                    error: nil,
                    errorType: nil,
                    delay: nil
                )
                timeline.addAttempt(attempt)
                return .simulationCompleted(timeline)
            } catch {
                let attempt = ErrorSimulationAttempt(
                    attemptNumber: attemptNumber,
                    success: false,
                    error: error.localizedDescription,
                    errorType: simulation.errorType,
                    delay: nil
                )
                timeline.addAttempt(attempt)
            }
        }
        
        while attemptNumber < simulation.maxRetries + 1 && !success {
            attemptNumber += 1
            let delay = simulation.nextDelay(for: attemptNumber - 1)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            let shouldFail = simulation.shouldFail()
            
            if shouldFail {
                let attempt = ErrorSimulationAttempt(
                    attemptNumber: attemptNumber,
                    success: false,
                    error: simulation.errorType.description,
                    errorType: simulation.errorType,
                    delay: delay
                )
                timeline.addAttempt(attempt)
            } else {
                let attempt = ErrorSimulationAttempt(
                    attemptNumber: attemptNumber,
                    success: true,
                    error: nil,
                    errorType: nil,
                    delay: delay
                )
                timeline.addAttempt(attempt)
                success = true
            }
        }
        
        return .simulationCompleted(timeline)
    }
}
