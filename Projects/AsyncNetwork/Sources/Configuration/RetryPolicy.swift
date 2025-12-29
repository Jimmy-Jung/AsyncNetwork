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
    private let configuration: RetryConfiguration
    private let rules: [any RetryRule]

    public init(
        configuration: RetryConfiguration = .default,
        rules: [any RetryRule] = [URLErrorRetryRule(), ServerErrorRetryRule()]
    ) {
        self.configuration = configuration
        self.rules = rules
    }

    public func shouldRetry(error: Error, attempt: Int) -> RetryDecision {
        // 0. 유효하지 않은 시도 횟수 확인
        guard attempt > 0 else {
            logRetryDecision(decision: .stop, reason: "Invalid attempt number: \(attempt)")
            return .stop
        }

        // 1. 최대 재시도 횟수 초과 확인
        guard attempt <= configuration.maxRetries else {
            logRetryDecision(decision: .stop, reason: "Max retries exceeded")
            return .stop
        }

        // 2. 룰 기반 재시도 가능성 체크
        // 룰이 true를 반환하면 재시도, false면 중단, nil이면 다음 룰로 패스
        let isRetryable = rules
            .lazy
            .compactMap { $0.shouldRetry(error: error) }
            .first ?? false // 어떤 룰도 매칭되지 않으면 재시도 안 함

        guard isRetryable else {
            logRetryDecision(decision: .stop, reason: "Error is not retryable: \(error)")
            return .stop
        }

        // 3. 지연 시간 계산
        let delay = calculateDelay(attempt: attempt)
        let decision = RetryDecision.retry(after: delay)

        logRetryDecision(decision: decision, reason: "Retryable error detected")
        return decision
    }

    public func calculateDelay(attempt: Int) -> TimeInterval {
        let transforms: [(Double) -> Double] = [
            { pow(2.0, $0) }, // 지수 계산
            { self.configuration.baseDelay * $0 }, // 기본 지연시간 적용
            addJitter, // 지터 추가
            { min($0, self.configuration.maxDelay) } // 최대 지연시간 제한
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
