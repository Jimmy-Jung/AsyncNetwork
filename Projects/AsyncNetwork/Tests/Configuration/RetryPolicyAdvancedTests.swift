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
        let config = RetryConfiguration.default

        // Then
        #expect(config.maxRetries == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 30.0)
    }

    @Test("RetryConfiguration - Aggressive 설정")
    func aggressiveConfiguration() {
        // Given & When
        let config = RetryConfiguration.aggressive

        // Then
        #expect(config.maxRetries == 5)
        #expect(config.baseDelay == 0.5)
    }

    @Test("RetryConfiguration - Conservative 설정")
    func conservativeConfiguration() {
        // Given & When
        let config = RetryConfiguration.conservative

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

    @Test("RetryDecision - 모든 케이스")
    func retryDecisionCases() {
        // Given
        let retry: RetryDecision = .retry(after: 1.0)
        let stop: RetryDecision = .stop
        let immediate: RetryDecision = .retryImmediately

        // Then
        switch retry {
        case let .retry(delay):
            #expect(delay == 1.0)
        default:
            Issue.record("Expected retry case")
        }

        switch stop {
        case .stop:
            #expect(true)
        default:
            Issue.record("Expected stop case")
        }

        switch immediate {
        case .retryImmediately:
            #expect(true)
        default:
            Issue.record("Expected retryImmediately case")
        }
    }
}
