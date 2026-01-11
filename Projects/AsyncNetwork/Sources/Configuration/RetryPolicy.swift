//
//  RetryPolicy.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

// MARK: - RetryConfiguration

/// 재시도 정책 설정
///
/// ## 알고리즘: Exponential Backoff + Jitter
///
/// ### 1️⃣ Exponential Backoff (지수 백오프)
/// 재시도 시 대기 시간을 지수적으로 증가시켜 서버 부하를 줄입니다.
/// ```
/// 기본 공식: baseDelay × 2^(attempt - 1)
///
/// 재시도 1회: 1초 × 2^0 = 1초
/// 재시도 2회: 1초 × 2^1 = 2초
/// 재시도 3회: 1초 × 2^2 = 4초
/// 재시도 4회: 1초 × 2^3 = 8초
/// 재시도 5회: 1초 × 2^4 = 16초
/// ```
///
/// ### 2️⃣ Jitter (지터)
/// 대기 시간에 랜덤 노이즈를 추가하여 동시 재시도를 방지합니다.
/// ```
/// jitter = 대기시간 × random(jitterRange)
/// 최종 대기시간 = 대기시간 + jitter
///
/// 예시 (jitterRange = 0.1...0.3):
/// 4초 → 4초 + (0.4~1.2초) = 4.4~5.2초
/// 8초 → 8초 + (0.8~2.4초) = 8.8~10.4초
/// ```
///
/// **왜 필요한가?**
/// - Exponential Backoff만 사용하면 모든 클라이언트가 정확히 같은 시간에 재시도
/// - Jitter 추가로 재시도 시간을 분산시켜 서버 부하 방지
/// - "Thundering Herd Problem" 해결
///
/// ## 파라미터 설명
///
/// - `maxRetries`: 최대 재시도 횟수 (0이면 재시도 없음)
/// - `baseDelay`: 첫 재시도의 기본 대기 시간 (초 단위)
/// - `maxDelay`: 최대 대기 시간 상한선 (아무리 길어도 이 시간을 초과하지 않음)
/// - `jitterRange`: 랜덤 추가 범위 (0.1~0.3 = 10~30% 랜덤 추가)
///
/// ## 사용 예시
///
/// ```swift
/// // 표준 재시도 (3회, 1초 기본 간격)
/// let config = RetryConfiguration.standard
///
/// // 빠른 재시도 (5회, 0.5초 기본 간격)
/// let config = RetryConfiguration.quick
///
/// // 느린 재시도 (1회, 2초 기본 간격)
/// let config = RetryConfiguration.patient
///
/// // 커스텀 설정
/// let config = RetryConfiguration(
///     maxRetries: 10,
///     baseDelay: 0.3,
///     maxDelay: 60.0,
///     jitterRange: 0.1...0.5
/// )
/// ```
public struct RetryConfiguration: Sendable {
    /// 최대 재시도 횟수 (0이면 재시도 없음)
    public let maxRetries: Int

    /// 첫 재시도의 기본 대기 시간 (초 단위)
    ///
    /// Exponential Backoff의 기준 값입니다.
    /// - 예: baseDelay = 1.0이면 1초 → 2초 → 4초 → 8초...
    public let baseDelay: TimeInterval

    /// 최대 대기 시간 상한선 (초 단위)
    ///
    /// Exponential Backoff는 무한히 증가할 수 있으므로 상한선을 설정합니다.
    /// - 예: maxDelay = 30이면 아무리 길어도 30초를 초과하지 않음
    public let maxDelay: TimeInterval

    /// 랜덤 지터 범위 (비율)
    ///
    /// 계산된 대기 시간에 추가할 랜덤 노이즈의 범위입니다.
    /// - 0.1...0.3 = 대기시간의 10~30%를 랜덤으로 추가
    /// - 예: 4초 대기 → 4초 + (0.4~1.2초) = 4.4~5.2초 사이 랜덤
    ///
    /// **목적**: 여러 클라이언트가 동시에 재시도하는 것을 방지하여 서버 부하 분산
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

    /// 표준 재시도: 3회, 1초 간격, 최대 30초 대기
    ///
    /// 일반적인 네트워크 요청에 적합합니다.
    /// ```
    /// 재시도 1회: ~1초
    /// 재시도 2회: ~2초
    /// 재시도 3회: ~4초
    /// ```
    public static let standard = RetryConfiguration()

    /// 빠른 재시도: 5회, 0.5초 간격, 최대 15초 대기
    ///
    /// 실시간성이 중요한 요청에 적합합니다 (채팅, 실시간 알림 등).
    /// ```
    /// 재시도 1회: ~0.5초
    /// 재시도 2회: ~1초
    /// 재시도 3회: ~2초
    /// 재시도 4회: ~4초
    /// 재시도 5회: ~8초
    /// ```
    public static let quick = RetryConfiguration(
        maxRetries: 5,
        baseDelay: 0.5,
        maxDelay: 15.0
    )

    /// 느린 재시도: 1회, 2초 간격
    ///
    /// 중요하지 않거나 부하가 많은 요청에 적합합니다.
    /// ```
    /// 재시도 1회: ~2초
    /// ```
    public static let patient = RetryConfiguration(
        maxRetries: 1,
        baseDelay: 2.0
    )
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
        configuration: RetryConfiguration = .standard,
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

    /// 재시도 대기 시간 계산 (Exponential Backoff + Jitter)
    ///
    /// ## 계산 단계:
    /// ```
    /// 1. Exponential: 2^(attempt - 1)
    ///    - attempt 1: 2^0 = 1
    ///    - attempt 2: 2^1 = 2
    ///    - attempt 3: 2^2 = 4
    ///    - attempt 4: 2^3 = 8
    ///
    /// 2. Base Delay 곱하기: baseDelay × exponential
    ///    - 1초 × 1 = 1초
    ///    - 1초 × 2 = 2초
    ///    - 1초 × 4 = 4초
    ///    - 1초 × 8 = 8초
    ///
    /// 3. Jitter 추가: delay + (delay × random(jitterRange))
    ///    - 4초 + (4초 × 0.15) = 4.6초
    ///    - 8초 + (8초 × 0.22) = 9.76초
    ///
    /// 4. Max Delay 제한: min(delay, maxDelay)
    ///    - 계산 결과가 35초여도 maxDelay=30이면 30초
    /// ```
    public func calculateDelay(attempt: Int) -> TimeInterval {
        // 함수형 스타일로 순차적으로 변환 적용
        let transforms: [(Double) -> Double] = [
            // 1️⃣ Exponential Backoff: 2^(attempt-1)
            { pow(2.0, $0) },

            // 2️⃣ Base Delay 적용: exponential × baseDelay
            { self.configuration.baseDelay * $0 },

            // 3️⃣ Jitter 추가: delay + random
            addJitter,

            // 4️⃣ Max Delay 제한
            { min($0, self.configuration.maxDelay) },
        ]

        return transforms.reduce(Double(attempt - 1)) { value, transform in
            transform(value)
        }
    }

    /// Jitter 추가 (랜덤 노이즈)
    ///
    /// 대기 시간의 일정 비율(jitterRange)을 랜덤으로 추가합니다.
    ///
    /// **예시**:
    /// ```
    /// delay = 4초, jitterRange = 0.1...0.3
    /// jitter = 4초 × random(0.1...0.3) = 0.4~1.2초
    /// 최종 = 4초 + jitter = 4.4~5.2초
    /// ```
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
