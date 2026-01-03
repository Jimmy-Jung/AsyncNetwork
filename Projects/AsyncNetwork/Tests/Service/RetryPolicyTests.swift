//
//  RetryPolicyTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - RetryPolicyTests

struct RetryPolicyTests {
    // MARK: - Properties

    private let defaultPolicy = RetryPolicy()
    private let aggressivePolicy = RetryPolicy.aggressive
    private let conservativePolicy = RetryPolicy.conservative
    private let noRetryPolicy = RetryPolicy.none

    // MARK: - Retry Configuration Tests

    @Test("기본 재시도 설정 생성")
    func validateDefaultRetryConfiguration() {
        // Given & When
        let config = RetryConfiguration.default

        // Then
        #expect(config.maxRetries == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 30.0)
        #expect(config.jitterRange.lowerBound == 0.1)
        #expect(config.jitterRange.upperBound == 0.3)
    }

    @Test("적극적 재시도 설정 생성")
    func validateAggressiveRetryConfiguration() {
        // Given & When
        let config = RetryConfiguration.aggressive

        // Then
        #expect(config.maxRetries == 5)
        #expect(config.baseDelay == 0.5)
        #expect(config.maxDelay == 30.0)
    }

    @Test("보수적 재시도 설정 생성")
    func validateConservativeRetryConfiguration() {
        // Given & When
        let config = RetryConfiguration.conservative

        // Then
        #expect(config.maxRetries == 1)
        #expect(config.baseDelay == 2.0)
        #expect(config.maxDelay == 30.0)
    }

    @Test("커스텀 재시도 설정 생성")
    func validateCustomRetryConfiguration() {
        // Given & When
        let config = RetryConfiguration(
            maxRetries: 10,
            baseDelay: 0.1,
            maxDelay: 60.0,
            jitterRange: 0.05 ... 0.15
        )

        // Then
        #expect(config.maxRetries == 10)
        #expect(config.baseDelay == 0.1)
        #expect(config.maxDelay == 60.0)
        #expect(config.jitterRange.lowerBound == 0.05)
        #expect(config.jitterRange.upperBound == 0.15)
    }

    // MARK: - StatusCodeValidationError Retry Tests

    @Test("StatusCodeValidationError 서버 에러에 대해 재시도 결정")
    func shouldRetryStatusCodeValidationServerError() {
        // Given
        let serverError = StatusCodeValidationError.serverError(500, Data())

        // When
        let decision = defaultPolicy.shouldRetry(error: serverError, attempt: 1)

        // Then
        switch decision {
        case let .retry(delay):
            #expect(delay > 0)
        case .stop, .retryImmediately:
            #expect(Bool(false), "서버 에러는 재시도되어야 함")
        }
    }

    @Test("StatusCodeValidationError 클라이언트 에러에 대해 재시도 중단")
    func shouldNotRetryStatusCodeValidationClientError() {
        // Given
        let clientError = StatusCodeValidationError.clientError(400, Data())

        // When
        let decision = defaultPolicy.shouldRetry(error: clientError, attempt: 1)

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "클라이언트 에러는 재시도되지 않아야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "클라이언트 에러는 재시도되지 않아야 함")
        }
    }

    // MARK: - URLError Retry Tests

    @Test("재시도 가능한 URLError에 대해 재시도 결정", arguments: [
        URLError.networkConnectionLost,
        URLError.timedOut,
        URLError.cannotFindHost,
        URLError.cannotConnectToHost,
        URLError.dnsLookupFailed,
        URLError.notConnectedToInternet
    ])
    func shouldRetryRetryableURLError(urlErrorCode: URLError.Code) {
        // Given
        let urlError = URLError(urlErrorCode)

        // When
        let decision = defaultPolicy.shouldRetry(error: urlError, attempt: 1)

        // Then
        switch decision {
        case let .retry(delay):
            #expect(delay > 0)
        case .stop, .retryImmediately:
            #expect(Bool(false), "재시도 가능한 URLError는 재시도되어야 함")
        }
    }

    @Test("재시도 불가능한 URLError에 대해 재시도 중단")
    func shouldNotRetryNonRetryableURLError() {
        // Given
        let urlError = URLError(.badURL)

        // When
        let decision = defaultPolicy.shouldRetry(error: urlError, attempt: 1)

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "재시도 불가능한 URLError는 중단되어야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "재시도 불가능한 URLError는 재시도되지 않아야 함")
        }
    }

    // MARK: - Max Retries Tests

    @Test("최대 재시도 횟수 초과 시 재시도 중단")
    func shouldStopAfterMaxRetries() {
        // Given
        let retryableError = URLError(.networkConnectionLost)

        // When
        let decision = defaultPolicy.shouldRetry(error: retryableError, attempt: 4) // maxRetries = 3

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "최대 재시도 횟수 초과 시 중단되어야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "최대 재시도 횟수 초과 시 재시도되지 않아야 함")
        }
    }

    @Test("최대 재시도 횟수 내에서 재시도 결정")
    func shouldRetryWithinMaxRetries() {
        // Given
        let retryableError = URLError(.networkConnectionLost)

        // When
        let decision1 = defaultPolicy.shouldRetry(error: retryableError, attempt: 1)
        let decision2 = defaultPolicy.shouldRetry(error: retryableError, attempt: 2)
        let decision3 = defaultPolicy.shouldRetry(error: retryableError, attempt: 3)

        // Then
        for decision in [decision1, decision2, decision3] {
            switch decision {
            case let .retry(delay):
                #expect(delay > 0)
            case .stop, .retryImmediately:
                #expect(Bool(false), "최대 재시도 횟수 내에서는 재시도되어야 함")
            }
        }
    }

    // MARK: - Delay Calculation Tests

    @Test("지수 백오프 지연 시간 계산")
    func calculateExponentialBackoffDelay() {
        // When
        let delay1 = defaultPolicy.calculateDelay(attempt: 1) // 2^0 * 1.0 = 1.0
        let delay2 = defaultPolicy.calculateDelay(attempt: 2) // 2^1 * 1.0 = 2.0
        let delay3 = defaultPolicy.calculateDelay(attempt: 3) // 2^2 * 1.0 = 4.0
        let delay4 = defaultPolicy.calculateDelay(attempt: 4) // 2^3 * 1.0 = 8.0

        // Then
        #expect(delay1 >= 1.0)
        #expect(delay2 >= 2.0)
        #expect(delay3 >= 4.0)
        #expect(delay4 >= 8.0)
        #expect(delay2 > delay1)
        #expect(delay3 > delay2)
        #expect(delay4 > delay3)
    }

    @Test("최대 지연 시간 제한")
    func validateMaxDelayLimit() {
        // When
        let delay = defaultPolicy.calculateDelay(attempt: 10) // 매우 큰 지연 시간

        // Then
        #expect(delay <= 30.0) // maxDelay = 30.0
    }

    @Test("지터가 지연 시간에 추가됨")
    func validateJitterAddedToDelay() {
        // When
        let delay1 = defaultPolicy.calculateDelay(attempt: 2)
        let delay2 = defaultPolicy.calculateDelay(attempt: 2)
        let delay3 = defaultPolicy.calculateDelay(attempt: 2)

        // Then - 지터로 인해 같은 시도 횟수라도 약간씩 다른 지연 시간
        #expect(delay1 != delay2 || delay2 != delay3 || delay1 != delay3)
    }

    // MARK: - Policy Preset Tests

    @Test("기본 재시도 정책")
    func validateDefaultRetryPolicy() {
        // Given & When
        let policy = RetryPolicy.default

        // Then
        _ = policy // 사용되었음을 표시
    }

    @Test("적극적 재시도 정책")
    func validateAggressiveRetryPolicy() {
        // Given & When
        let policy = RetryPolicy.aggressive

        // Then
        _ = policy // 사용되었음을 표시
    }

    @Test("보수적 재시도 정책")
    func validateConservativeRetryPolicy() {
        // Given & When
        let policy = RetryPolicy.conservative

        // Then
        _ = policy // 사용되었음을 표시
    }

    @Test("재시도 없음 정책")
    func validateNoRetryPolicy() {
        // Given & When
        let policy = RetryPolicy.none

        // Then
        _ = policy // 사용되었음을 표시
    }

    // MARK: - Edge Cases

    @Test("0번째 시도는 재시도 결정하지 않음")
    func shouldNotRetryOnZeroAttempt() {
        // Given
        let retryableError = URLError(.networkConnectionLost)

        // When
        let decision = defaultPolicy.shouldRetry(error: retryableError, attempt: 0)

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "0번째 시도는 재시도되지 않아야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "0번째 시도는 재시도되지 않아야 함")
        }
    }

    @Test("음수 시도 횟수는 재시도 결정하지 않음")
    func shouldNotRetryOnNegativeAttempt() {
        // Given
        let retryableError = URLError(.networkConnectionLost)

        // When
        let decision = defaultPolicy.shouldRetry(error: retryableError, attempt: -1)

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "음수 시도 횟수는 재시도되지 않아야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "음수 시도 횟수는 재시도되지 않아야 함")
        }
    }

    @Test("알 수 없는 에러는 재시도하지 않음")
    func shouldNotRetryUnknownError() {
        // Given
        struct UnknownError: Error {
            let message: String
        }
        let unknownError = UnknownError(message: "Unknown error")

        // When
        let decision = defaultPolicy.shouldRetry(error: unknownError, attempt: 1)

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "알 수 없는 에러는 재시도되지 않아야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "알 수 없는 에러는 재시도되지 않아야 함")
        }
    }

    // MARK: - RetryDecision Tests

    @Test("RetryDecision.retry 지연 시간 확인")
    func validateRetryDecisionDelay() {
        // Given
        let retryableError = URLError(.networkConnectionLost)

        // When
        let decision = defaultPolicy.shouldRetry(error: retryableError, attempt: 1)

        // Then
        switch decision {
        case let .retry(delay):
            #expect(delay > 0)
            #expect(delay <= 30.0) // maxDelay 제한
        case .stop, .retryImmediately:
            #expect(Bool(false), "재시도 가능한 에러는 재시도되어야 함")
        }
    }

    @Test("RetryDecision.stop 확인")
    func validateRetryDecisionStop() {
        // Given
        let nonRetryableError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test")
        )

        // When
        let decision = defaultPolicy.shouldRetry(error: nonRetryableError, attempt: 1)

        // Then
        switch decision {
        case .stop:
            #expect(Bool(true), "재시도 불가능한 에러는 중단되어야 함")
        case .retry, .retryImmediately:
            #expect(Bool(false), "재시도 불가능한 에러는 재시도되지 않아야 함")
        }
    }
}
