//
//  ErrorSimulatorViewModel.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
import AsyncViewModel
import Foundation

// MARK: - Test APIRequests

/// 정상 요청 (실제 API)
@APIRequest(
    response: [PostDTO].self,
    title: "Get posts for error simulation",
    baseURL: "https://jsonplaceholder.typicode.com",
    path: "/posts",
    method: .get
)
struct ErrorSimulatorGetPostsRequest {}

/// 네트워크 연결 끊김 시뮬레이션 (존재하지 않는 도메인)
@APIRequest(
    response: [PostDTO].self,
    title: "Network disconnected simulation",
    baseURL: "https://this-domain-does-not-exist-for-network-error-simulation-12345.com",
    path: "/posts",
    method: .get
)
struct NetworkDisconnectedRequest {}

/// 타임아웃 시뮬레이션 (느린 서버)
@APIRequest(
    response: EmptyResponseDto.self,
    title: "Timeout simulation",
    baseURL: "https://httpstat.us",
    path: "/200",
    method: .get
)
struct TimeoutRequest {
    @QueryParameter var sleep: Int? // 밀리초 단위 지연 (옵셔널)

    init(sleep: Int? = 10000) {
        self.sleep = sleep
    }
}

/// Not Found 시뮬레이션
@APIRequest(
    response: EmptyResponseDto.self,
    title: "Not found simulation",
    baseURL: "https://jsonplaceholder.typicode.com",
    path: "/this-endpoint-does-not-exist",
    method: .get
)
struct NotFoundRequest {}

/// Server Error 시뮬레이션
@APIRequest(
    response: EmptyResponseDto.self,
    title: "Server error simulation",
    baseURL: "https://httpstat.us",
    path: "/500",
    method: .get
)
struct ServerErrorRequest {}

/// Unauthorized 시뮬레이션
@APIRequest(
    response: EmptyResponseDto.self,
    title: "Unauthorized simulation",
    baseURL: "https://httpstat.us",
    path: "/401",
    method: .get
)
struct UnauthorizedRequest {}

/// Bad Request 시뮬레이션
@APIRequest(
    response: EmptyResponseDto.self,
    title: "Bad request simulation",
    baseURL: "https://httpstat.us",
    path: "/400",
    method: .get
)
struct BadRequestRequest {}

/// Error Simulator ViewModel
@AsyncViewModel
@MainActor
final class ErrorSimulatorViewModel {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case errorTypeSelected(SimulatedErrorType)
        case startSimulationTapped
        case cancelSimulationTapped
        case clearResultsTapped
    }

    enum Action: Equatable, Sendable {
        // Input → Action
        case errorTypeChanged(SimulatedErrorType)
        case startSimulation
        case cancelSimulation
        case clearResults

        // Effect → Action
        case simulationResultReceived(ErrorSimulationResult)
        case simulationBatchCompleted([ErrorSimulationResult])
        case simulationCompleted
    }

    struct State: Equatable, Sendable {
        var selectedErrorType: SimulatedErrorType = .none
        var isSimulating: Bool = false
        var results: [ErrorSimulationResult] = []
        var currentAttempt: Int = 0
        var maxRetries: Int = 3
    }

    enum CancelID: Hashable, Sendable {
        case simulation
    }

    // MARK: - Properties

    @Published var state: State
    var timer: any AsyncTimer = SystemTimer()

    private let networkService: NetworkService

    // MARK: - Initialization

    init(networkService: NetworkService? = nil) {
        state = State()

        // NetworkService 설정 (ConsoleLoggingInterceptor + RetryPolicy)
        if let service = networkService {
            self.networkService = service
        } else {
            // 기본 설정: Verbose 로깅 + 재시도 정책
            let configuration = NetworkConfiguration(
                maxRetries: 3,
                retryDelay: 1.0,
                timeout: 5.0, // 5초 타임아웃
                enableLogging: true,
                checkNetworkBeforeRequest: false // 에러 시뮬레이터는 네트워크 체크 비활성화
            )

            self.networkService = NetworkService(
                configuration: configuration,
                plugins: [
                    ConsoleLoggingInterceptor(minimumLevel: .verbose)
                ]
            )
        }
    }

    // MARK: - AsyncViewModel Protocol

    func transform(_ input: Input) -> [Action] {
        switch input {
        case let .errorTypeSelected(type):
            return [.errorTypeChanged(type)]
        case .startSimulationTapped:
            return [.startSimulation]
        case .cancelSimulationTapped:
            return [.cancelSimulation]
        case .clearResultsTapped:
            return [.clearResults]
        }
    }

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .errorTypeChanged(type):
            state.selectedErrorType = type
            return []

        case .startSimulation:
            state.isSimulating = true
            state.results = []
            state.currentAttempt = 0
            return [createSimulationEffect(errorType: state.selectedErrorType)]

        case .cancelSimulation:
            state.isSimulating = false
            return [.cancel(id: .simulation)]

        case .clearResults:
            state.results = []
            state.currentAttempt = 0
            return []

        case let .simulationResultReceived(result):
            state.results.append(result)
            state.isSimulating = false
            return []

        case let .simulationBatchCompleted(results):
            state.results.append(contentsOf: results)
            state.isSimulating = false
            return []

        case .simulationCompleted:
            state.isSimulating = false
            return []
        }
    }

    func handleError(_ error: SendableError) {
        print("ErrorSimulatorViewModel Error: \(error.localizedDescription)")
    }

    // MARK: - Private Helper Methods

    private func createSimulationEffect(
        errorType: SimulatedErrorType
    ) -> AsyncEffect<Action, CancelID> {
        .run(id: .simulation) { [networkService = self.networkService] in
            let start = Date()

            do {
                let responseInfo = try await self.performRequest(
                    errorType: errorType,
                    networkService: networkService
                )
                let duration = Date().timeIntervalSince(start)
                return .simulationResultReceived(
                    .success(
                        url: responseInfo.url,
                        statusCode: responseInfo.statusCode,
                        duration: duration
                    )
                )
            } catch {
                let duration = Date().timeIntervalSince(start)
                let errorURL = self.extractErrorURL(from: error)
                let willRetry = self.shouldRetry(error: error)

                return .simulationResultReceived(
                    .failure(
                        url: errorURL,
                        errorType: errorType,
                        attempt: 1,
                        willRetry: willRetry,
                        duration: duration
                    )
                )
            }
        }
    }

    private func performRequest(
        errorType: SimulatedErrorType,
        networkService: NetworkService
    ) async throws -> (url: String, statusCode: Int) {
        switch errorType {
        case .none:
            let result: [PostDTO] = try await networkService.request(
                ErrorSimulatorGetPostsRequest()
            )
            _ = try JSONEncoder().encode(result)
            return (
                url: "https://jsonplaceholder.typicode.com/posts",
                statusCode: 200
            )

        case .networkConnectionLost:
            let _: [PostDTO] = try await networkService.request(
                NetworkDisconnectedRequest()
            )
            return (
                url: "https://this-domain-does-not-exist...",
                statusCode: 0
            )

        case .timeout:
            let _: EmptyResponseDto = try await networkService.request(
                TimeoutRequest(sleep: 10000)
            )
            return (
                url: "https://httpstat.us/200?sleep=10000",
                statusCode: 0
            )

        case .notFound:
            let _: EmptyResponseDto = try await networkService.request(
                NotFoundRequest()
            )
            return (
                url: "https://jsonplaceholder.typicode.com/this-endpoint-does-not-exist",
                statusCode: 404
            )

        case .serverError:
            let _: EmptyResponseDto = try await networkService.request(
                ServerErrorRequest()
            )
            return (url: "https://httpstat.us/500", statusCode: 500)

        case .unauthorized:
            let _: EmptyResponseDto = try await networkService.request(
                UnauthorizedRequest()
            )
            return (url: "https://httpstat.us/401", statusCode: 401)

        case .badRequest:
            let _: EmptyResponseDto = try await networkService.request(
                BadRequestRequest()
            )
            return (url: "https://httpstat.us/400", statusCode: 400)
        }
    }

    private func extractErrorURL(from error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "Unknown URL"
        }

        switch networkError {
        case let .invalidURL(urlString):
            return urlString
        case let .connectionError(underlyingError):
            return underlyingError.failureURLString ?? "Unknown URL"
        default:
            return "Unknown URL"
        }
    }

    private func shouldRetry(error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return false
        }

        switch networkError {
        case .connectionError, .offline:
            return true
        case let .httpError(statusError):
            return statusError.statusCode >= 500
        default:
            return false
        }
    }
}
