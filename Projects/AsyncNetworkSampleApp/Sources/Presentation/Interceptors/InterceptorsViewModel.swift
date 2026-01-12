//
//  InterceptorsViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/12.
//

import AsyncNetwork
import AsyncViewModel
import Foundation

/// Request Interceptors 화면 전용 ViewModel
@AsyncViewModel
@MainActor
final class InterceptorsViewModel {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case viewDidAppear
        case viewDidDisappear

        // Interceptor
        case interceptorToggled(InterceptorType)
        case testInterceptorsTapped
        case clearInterceptorLogsTapped
    }

    enum Action: Equatable, Sendable {
        case viewDidAppear
        case viewDidDisappear

        // Interceptor
        case toggleInterceptor(InterceptorType)
        case executeInterceptorTest
        case clearInterceptorLogs
        case interceptorTestCompleted(InterceptorTestResult)
        case interceptorTestFailed(String)
    }

    struct State: Equatable, Sendable {
        var interceptorConfig: InterceptorConfig = .init()
        var isExecutingInterceptorTest: Bool = false
        var interceptorTestResults: [InterceptorTestResult] = []
        var interceptorErrorMessage: String?
    }

    enum CancelID: Hashable, Sendable {
        case interceptorTest
    }

    // MARK: - Properties

    @Published var state: State
    var timer: any AsyncTimer = SystemTimer()

    private let runtimeInterceptorManager: RuntimeInterceptorManager?
    private let getPostsUseCase: GetPostsUseCase

    // MARK: - Initialization

    init(
        runtimeInterceptorManager: RuntimeInterceptorManager? = nil,
        getPostsUseCase: GetPostsUseCase? = nil
    ) {
        state = State()
        self.runtimeInterceptorManager = runtimeInterceptorManager
        self.getPostsUseCase = getPostsUseCase ?? AppDependency.shared.getPostsUseCase

        // runtimeInterceptorManager가 있으면 초기 상태 동기화
        if let manager = runtimeInterceptorManager {
            state.interceptorConfig = InterceptorConfig(
                enabledInterceptors: manager.activeInterceptors
            )
        }
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .viewDidAppear:
            return [.viewDidAppear]
        case .viewDidDisappear:
            return [.viewDidDisappear]
        case let .interceptorToggled(type):
            return [.toggleInterceptor(type)]
        case .testInterceptorsTapped:
            return [.executeInterceptorTest]
        case .clearInterceptorLogsTapped:
            return [.clearInterceptorLogs]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .viewDidAppear:
            return []

        case .viewDidDisappear:
            return [.cancel(id: .interceptorTest)]

        case let .toggleInterceptor(type):
            state.interceptorConfig.toggle(type)
            state.interceptorErrorMessage = nil

            // 실제 NetworkService의 인터셉터 업데이트
            if let manager = runtimeInterceptorManager {
                manager.toggle(type)
            }

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
        }
    }

    func handleError(_: SendableError) {
        // 에러 처리
    }

    // MARK: - Private Methods

    private func executeInterceptorTest(with config: InterceptorConfig) async -> Action {
        let startTime = Date()

        do {
            // 실제 네트워크 요청 실행
            _ = try await getPostsUseCase.execute()
            let duration = Date().timeIntervalSince(startTime)

            // 테스트 결과 생성
            let result = InterceptorTestResult(
                success: true,
                requestURL: "https://jsonplaceholder.typicode.com/posts",
                statusCode: 200,
                duration: duration,
                logs: generateMockLogs(for: config)
            )

            return .interceptorTestCompleted(result)
        } catch {
            let duration = Date().timeIntervalSince(startTime)

            let result = InterceptorTestResult(
                success: false,
                requestURL: "https://jsonplaceholder.typicode.com/posts",
                statusCode: nil,
                duration: duration,
                logs: generateMockLogs(for: config)
            )

            return .interceptorTestCompleted(result)
        }
    }

    private func generateMockLogs(for config: InterceptorConfig) -> [InterceptorLog] {
        var logs: [InterceptorLog] = []

        for type in config.activeInterceptors {
            switch type {
            case .etag:
                logs.append(InterceptorLog(
                    interceptorType: type,
                    action: "prepare",
                    details: "ETag 캐시 확인 및 If-None-Match 헤더 추가"
                ))
            case .auth:
                logs.append(InterceptorLog(
                    interceptorType: type,
                    action: "prepare",
                    details: "Added Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                ))
            case .customHeader:
                logs.append(InterceptorLog(
                    interceptorType: type,
                    action: "prepare",
                    details: "Added X-Custom-Header: AsyncNetwork-Demo"
                ))
            case .timestamp:
                logs.append(InterceptorLog(
                    interceptorType: type,
                    action: "prepare",
                    details: "Added X-Timestamp: \(Date().timeIntervalSince1970)"
                ))
            case .consoleLogging:
                logs.append(InterceptorLog(
                    interceptorType: type,
                    action: "willSend",
                    details: "Logging request to console"
                ))
            }
        }

        return logs
    }
}
