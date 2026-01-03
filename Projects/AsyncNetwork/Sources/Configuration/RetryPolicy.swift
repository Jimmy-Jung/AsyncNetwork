//
//  RetryPolicy.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

public struct RetryConfiguration: Sendable {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let jitterRange: ClosedRange<Double>

    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        jitterRange: ClosedRange<Double> = 0.1 ... 0.3
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterRange = jitterRange
    }

    public static let `default` = RetryConfiguration()
    public static let aggressive = RetryConfiguration(maxRetries: 5, baseDelay: 0.5)
    public static let conservative = RetryConfiguration(maxRetries: 1, baseDelay: 2.0)
}

public enum RetryDecision {
    case retry(after: TimeInterval)
    case stop
    case retryImmediately
}

public struct RetryPolicy: Sendable {
    public let configuration: RetryConfiguration
    private let rules: [any RetryRule]

    public init(
        configuration: RetryConfiguration = .default,
        rules: [any RetryRule] = [URLErrorRetryRule(), ServerErrorRetryRule()]
    ) {
        self.configuration = configuration
        self.rules = rules
    }

    public func shouldRetry(error: Error, attempt: Int) -> RetryDecision {
        guard attempt > 0 else {
            logRetryDecision(decision: .stop, reason: "Invalid attempt number: \(attempt)")
            return .stop
        }

        guard attempt <= configuration.maxRetries else {
            logRetryDecision(decision: .stop, reason: "Max retries exceeded")
            return .stop
        }

        let isRetryable = rules
            .lazy
            .compactMap { $0.shouldRetry(error: error) }
            .first ?? false

        guard isRetryable else {
            logRetryDecision(decision: .stop, reason: "Error is not retryable: \(error)")
            return .stop
        }

        let delay = calculateDelay(attempt: attempt)
        let decision = RetryDecision.retry(after: delay)

        logRetryDecision(decision: decision, reason: "Retryable error detected")
        return decision
    }

    public func calculateDelay(attempt: Int) -> TimeInterval {
        let transforms: [(Double) -> Double] = [
            { pow(2.0, $0) },
            { self.configuration.baseDelay * $0 },
            addJitter,
            { min($0, self.configuration.maxDelay) }
        ]

        return transforms.reduce(Double(attempt - 1)) { value, transform in
            transform(value)
        }
    }

    private func addJitter(_ delay: TimeInterval) -> TimeInterval {
        let jitter = Double.random(in: configuration.jitterRange) * delay
        return delay + jitter
    }

    private func logRetryDecision(decision: RetryDecision, reason: String) {
        #if DEBUG
            switch decision {
            case let .retry(delay):
                print("🔄 [RetryPolicy] Will retry after \(String(format: "%.2f", delay))s - \(reason)")
            case .stop:
                print("🛑 [RetryPolicy] Will not retry - \(reason)")
            case .retryImmediately:
                print("⚡ [RetryPolicy] Will retry immediately - \(reason)")
            }
        #endif
    }
}

public extension RetryPolicy {
    static let `default` = RetryPolicy()
    static let aggressive = RetryPolicy(configuration: .aggressive)
    static let conservative = RetryPolicy(configuration: .conservative)
    static let none = RetryPolicy(
        configuration: RetryConfiguration(maxRetries: 0),
        rules: []
    )
}
