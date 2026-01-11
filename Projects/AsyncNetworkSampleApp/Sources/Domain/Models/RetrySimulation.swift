//
//  RetrySimulation.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

// MARK: - RetrySimulation

/// 재시도 시뮬레이션 설정
struct RetrySimulation: Equatable, Sendable {
    var preset: RetryPolicyPreset
    var maxRetries: Int
    var baseDelay: TimeInterval
    var shouldFail: Bool // 시뮬레이션을 위한 강제 실패 설정

    init(
        preset: RetryPolicyPreset = .standard,
        maxRetries: Int? = nil,
        baseDelay: TimeInterval? = nil,
        shouldFail: Bool = false
    ) {
        self.preset = preset
        self.maxRetries = maxRetries ?? preset.maxRetries
        self.baseDelay = baseDelay ?? preset.baseDelay
        self.shouldFail = shouldFail
    }

    func nextDelay(for attempt: Int) -> TimeInterval {
        // Exponential backoff with jitter
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        let jitter = Double.random(in: 0 ... 0.1) * exponentialDelay
        return exponentialDelay + jitter
    }
}

// MARK: - RetryAttempt

/// 재시도 시도 정보
struct RetryAttempt: Equatable, Sendable, Identifiable {
    let id: UUID
    let attemptNumber: Int
    let timestamp: Date
    let success: Bool
    let error: String?
    let delay: TimeInterval?

    init(
        attemptNumber: Int,
        timestamp: Date = Date(),
        success: Bool,
        error: String? = nil,
        delay: TimeInterval? = nil
    ) {
        id = UUID()
        self.attemptNumber = attemptNumber
        self.timestamp = timestamp
        self.success = success
        self.error = error
        self.delay = delay
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    var formattedDelay: String? {
        guard let delay = delay else { return nil }
        return String(format: "%.2f초", delay)
    }
}

// MARK: - RetryTimeline

/// 재시도 타임라인
struct RetryTimeline: Equatable, Sendable {
    let simulation: RetrySimulation
    var attempts: [RetryAttempt]
    let startTime: Date
    var endTime: Date?

    init(simulation: RetrySimulation) {
        self.simulation = simulation
        attempts = []
        startTime = Date()
        endTime = nil
    }

    mutating func addAttempt(_ attempt: RetryAttempt) {
        attempts.append(attempt)
        if attempt.success || attempts.count > simulation.maxRetries {
            endTime = Date()
        }
    }

    var totalDuration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        String(format: "%.2f초", totalDuration)
    }

    var successRate: Double {
        guard !attempts.isEmpty else { return 0 }
        let successCount = attempts.filter { $0.success }.count
        return Double(successCount) / Double(attempts.count)
    }

    var isCompleted: Bool {
        endTime != nil
    }
}
