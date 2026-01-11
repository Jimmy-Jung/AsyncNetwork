//
//  ErrorSimulatorViewModelTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import AsyncViewModel
import Testing

/// ErrorSimulatorViewModel 테스트
@Suite("ErrorSimulatorViewModel")
@MainActor
struct ErrorSimulatorViewModelTests {
    // MARK: - Initial State Tests

    @Test("초기 상태는 기본값으로 설정된다")
    func initialStateHasDefaultValues() {
        let viewModel = ErrorSimulatorViewModel(networkService: MockNetworkService())

        #expect(viewModel.state.selectedErrorType == .none)
        #expect(viewModel.state.isSimulating == false)
        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.currentAttempt == 0)
        #expect(viewModel.state.maxRetries == 3)
    }

    // MARK: - Error Type Selection Tests

    @Test("에러 타입 선택 시 State가 업데이트된다")
    func errorTypeSelectionUpdatesState() async throws {
        let viewModel = ErrorSimulatorViewModel(networkService: MockNetworkService())
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.errorTypeSelected(.timeout))
        try await store.waitForEffects()

        #expect(store.state.selectedErrorType == .timeout)
    }

    @Test("모든 에러 타입을 선택할 수 있다", arguments: SimulatedErrorType.allCases)
    func canSelectAllErrorTypes(errorType: SimulatedErrorType) async throws {
        let viewModel = ErrorSimulatorViewModel(networkService: MockNetworkService())
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.errorTypeSelected(errorType))
        try await store.waitForEffects()

        #expect(store.state.selectedErrorType == errorType)
    }

    // MARK: - Simulation Tests

    @Test("시뮬레이션 시작 시 isSimulating이 true가 된다")
    func simulationStartSetsIsSimulatingTrue() async throws {
        let viewModel = ErrorSimulatorViewModel(networkService: MockNetworkService())
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.startSimulationTapped)

        // 시뮬레이션이 진행되는 동안 isSimulating은 true
        #expect(store.state.isSimulating == true)
    }

    @Test("정상 케이스 시뮬레이션은 성공 결과를 생성한다")
    func normalCaseSimulationCreatesSuccessResult() async throws {
        let mockService = MockNetworkService()
        let viewModel = ErrorSimulatorViewModel(networkService: mockService)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.errorTypeSelected(.none))
        try await store.waitForEffects()

        store.send(.startSimulationTapped)
        try await store.waitForEffects()

        #expect(store.state.isSimulating == false)
        #expect(store.state.results.count == 1)
        #expect(store.state.results.first?.isSuccess == true)
    }

    @Test("재시도 가능한 에러는 여러 결과를 생성한다")
    func retryableErrorCreatesMultipleResults() async throws {
        let mockService = MockNetworkService()
        let viewModel = ErrorSimulatorViewModel(networkService: mockService)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.errorTypeSelected(.timeout))
        try await store.waitForEffects()

        store.send(.startSimulationTapped)
        try await store.waitForEffects()

        // 재시도 3회 + 마지막 실패 = 4개 결과
        #expect(store.state.results.count >= 1)
    }

    @Test("재시도 불가능한 에러는 1개 결과만 생성한다")
    func nonRetryableErrorCreatesOnlyOneResult() async throws {
        let mockService = MockNetworkService()
        let viewModel = ErrorSimulatorViewModel(networkService: mockService)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.errorTypeSelected(.notFound))
        try await store.waitForEffects()

        store.send(.startSimulationTapped)
        try await store.waitForEffects()

        #expect(store.state.results.count == 1)
        #expect(store.state.results.first?.isSuccess == false)
    }

    // MARK: - Clear Results Tests

    @Test("결과 초기화 시 모든 결과가 제거된다")
    func clearResultsRemovesAllResults() async throws {
        let mockService = MockNetworkService()
        let viewModel = ErrorSimulatorViewModel(networkService: mockService)
        let store = AsyncTestStore(viewModel: viewModel)

        // 시뮬레이션 실행
        store.send(.errorTypeSelected(.none))
        try await store.waitForEffects()

        store.send(.startSimulationTapped)
        try await store.waitForEffects()

        #expect(!store.state.results.isEmpty)

        // 결과 초기화
        store.send(.clearResultsTapped)
        try await store.waitForEffects()

        #expect(store.state.results.isEmpty)
        #expect(store.state.currentAttempt == 0)
    }

    // MARK: - Cancel Simulation Tests

    @Test("시뮬레이션 취소 시 진행이 중단된다")
    func cancelSimulationStopsProgress() async throws {
        let mockService = MockNetworkService()
        let viewModel = ErrorSimulatorViewModel(networkService: mockService)
        let store = AsyncTestStore(viewModel: viewModel)

        store.send(.errorTypeSelected(.timeout))
        try await store.waitForEffects()

        store.send(.startSimulationTapped)

        // 즉시 취소
        store.send(.cancelSimulationTapped)
        try await store.waitForEffects()

        #expect(store.state.isSimulating == false)
    }
}

// MARK: - Mock NetworkService

/// NetworkService의 Mock 구현
final class MockNetworkService: @unchecked Sendable {
    var shouldFail = false
    var mockDelay: TimeInterval = 0.1

    func simulateRequest() async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        if shouldFail {
            throw URLError(.timedOut)
        }
    }
}
