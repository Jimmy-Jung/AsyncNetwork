//
//  RetryPolicyAdvancedTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - RetryPolicyAdvancedTests

struct RetryPolicyAdvancedTests {
    @Test("RetryConfiguration - 최대 재시도 횟수 0")
    func zeroMaxRetries() {
        // Given
        let config = RetryConfiguration(maxRetries: 0, baseDelay: 0.1)

        // Then
        #expect(config.maxRetries == 0)
    }

    @Test("RetryConfiguration - 매우 긴 지연 시간")
    func veryLongDelay() {
        // Given
        let config = RetryConfiguration(maxRetries: 3, baseDelay: 100.0)

        // Then
        #expect(config.baseDelay == 100.0)
    }

    @Test("RetryConfiguration - 재시도 횟수와 지연 시간 조합")
    func retryCountAndDelayCombination() {
        // Given
        let testCases: [(maxRetries: Int, baseDelay: TimeInterval)] = [
            (1, 0.5),
            (3, 1.0),
            (5, 2.0),
            (10, 0.1),
        ]

        // Then
        for (maxRetries, baseDelay) in testCases {
            let config = RetryConfiguration(maxRetries: maxRetries, baseDelay: baseDelay)
            #expect(config.maxRetries == maxRetries)
            #expect(config.baseDelay == baseDelay)
        }
    }

    @Test("RetryConfiguration - 기본 값 확인")
    func defaultConfiguration() {
        // Given & When
        let config = RetryConfiguration.standard

        // Then
        #expect(config.maxRetries == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 30.0)
    }

    @Test("RetryConfiguration - Aggressive 설정")
    func aggressiveConfiguration() {
        // Given & When
        let config = RetryConfiguration.quick

        // Then
        #expect(config.maxRetries == 5)
        #expect(config.baseDelay == 0.5)
    }

    @Test("RetryConfiguration - Conservative 설정")
    func conservativeConfiguration() {
        // Given & When
        let config = RetryConfiguration.patient

        // Then
        #expect(config.maxRetries == 1)
        #expect(config.baseDelay == 2.0)
    }

    @Test("RetryPolicy - 기본 생성")
    func createDefaultPolicy() {
        // Given & When
        let policy = RetryPolicy()

        // Then
        #expect(policy.configuration.maxRetries == 3)
    }

    @Test("RetryPolicy - 커스텀 설정으로 생성")
    func createPolicyWithCustomConfiguration() {
        // Given
        let config = RetryConfiguration(maxRetries: 5, baseDelay: 0.5)

        // When
        let policy = RetryPolicy(configuration: config)

        // Then
        #expect(policy.configuration.maxRetries == 5)
        #expect(policy.configuration.baseDelay == 0.5)
    }

    @Test("RetryDecision - retry(after:) 케이스")
    func retryDecisionRetryCase() {
        // Given & When
        let decision: RetryDecision = .retry(after: 1.5)

        // Then
        if case let .retry(delay) = decision {
            #expect(delay == 1.5)
        } else {
            Issue.record("Expected retry case")
        }
    }

    @Test("RetryDecision - stop 케이스")
    func retryDecisionStopCase() {
        // Given & When
        let decision: RetryDecision = .stop

        // Then
        if case .stop = decision {
            #expect(true)
        } else {
            Issue.record("Expected stop case")
        }
    }

    @Test("RetryDecision - retryImmediately 케이스")
    func retryDecisionImmediateCase() {
        // Given & When
        let decision: RetryDecision = .retryImmediately

        // Then
        if case .retryImmediately = decision {
            #expect(true)
        } else {
            Issue.record("Expected retryImmediately case")
        }
    }
}
