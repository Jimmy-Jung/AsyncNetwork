//
//  ErrorSimulationTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//  Updated by jimmy on 2026/01/12.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

/// ErrorSimulation 도메인 모델 테스트
@Suite("ErrorSimulation 도메인 모델")
struct ErrorSimulationTests {
    // MARK: - ErrorType Tests

    @Test("ErrorType은 모든 에러 타입을 제공한다")
    func errorTypeProvidesAllTypes() {
        let types = ErrorType.allCases

        #expect(types.count == 6)
        #expect(types.contains(.timeout))
        #expect(types.contains(.networkFailure))
        #expect(types.contains(.serverError))
        #expect(types.contains(.invalidResponse))
        #expect(types.contains(.unauthorized))
        #expect(types.contains(.notFound))
    }

    @Test("ErrorType의 displayName은 명확하다")
    func errorTypeDisplayNamesAreClear() {
        #expect(ErrorType.timeout.displayName == "Timeout")
        #expect(ErrorType.networkFailure.displayName == "Network Failure")
        #expect(ErrorType.serverError.displayName == "Server Error (500)")
        #expect(ErrorType.invalidResponse.displayName == "Invalid Response")
        #expect(ErrorType.unauthorized.displayName == "Unauthorized (401)")
        #expect(ErrorType.notFound.displayName == "Not Found (404)")
    }

    @Test("ErrorType의 description은 상세 정보를 제공한다")
    func errorTypeDescriptionsProvideDetails() {
        #expect(ErrorType.timeout.description.contains("시간"))
        #expect(ErrorType.networkFailure.description.contains("연결"))
        #expect(ErrorType.serverError.description.contains("서버"))
        #expect(ErrorType.invalidResponse.description.contains("응답"))
        #expect(ErrorType.unauthorized.description.contains("인증"))
        #expect(ErrorType.notFound.description.contains("찾을 수 없음"))
    }

    @Test("ErrorType의 statusCode는 HTTP 에러 코드를 반환한다")
    func errorTypeStatusCodeReturnsHTTPCode() {
        #expect(ErrorType.serverError.statusCode == 500)
        #expect(ErrorType.unauthorized.statusCode == 401)
        #expect(ErrorType.notFound.statusCode == 404)
        #expect(ErrorType.timeout.statusCode == nil)
        #expect(ErrorType.networkFailure.statusCode == nil)
        #expect(ErrorType.invalidResponse.statusCode == nil)
    }

    @Test("ErrorType의 icon은 SF Symbol 이름을 반환한다")
    func errorTypeIconReturnsSFSymbolName() {
        #expect(ErrorType.timeout.icon == "clock.badge.exclamationmark")
        #expect(ErrorType.networkFailure.icon == "wifi.slash")
        #expect(ErrorType.serverError.icon == "exclamationmark.triangle.fill")
        #expect(ErrorType.invalidResponse.icon == "exclamationmark.bubble")
        #expect(ErrorType.unauthorized.icon == "lock.slash")
        #expect(ErrorType.notFound.icon == "questionmark.folder")
    }

    @Test("ErrorType의 generateError는 NSError를 생성한다")
    func errorTypeGenerateErrorCreatesNSError() {
        let timeoutError = ErrorType.timeout.generateError() as NSError
        #expect(timeoutError.code == -1001)
        #expect(timeoutError.domain == "AsyncNetworkDemo")

        let networkError = ErrorType.networkFailure.generateError() as NSError
        #expect(networkError.code == -1009)

        let serverError = ErrorType.serverError.generateError() as NSError
        #expect(serverError.code == 500)

        let unauthorizedError = ErrorType.unauthorized.generateError() as NSError
        #expect(unauthorizedError.code == 401)

        let notFoundError = ErrorType.notFound.generateError() as NSError
        #expect(notFoundError.code == 404)
    }

    // MARK: - ErrorSimulation Tests

    @Test("ErrorSimulation은 기본값으로 생성된다")
    func errorSimulationCreatesWithDefaultValues() {
        let simulation = ErrorSimulation()

        #expect(simulation.errorType == .timeout)
        #expect(simulation.failureRate == 0.8)
    }

    @Test("ErrorSimulation은 커스텀 값으로 생성된다")
    func errorSimulationCreatesWithCustomValues() {
        let simulation = ErrorSimulation(
            errorType: .notFound,
            failureRate: 0.5
        )

        #expect(simulation.errorType == .notFound)
        #expect(simulation.failureRate == 0.5)
    }

    @Test("ErrorSimulation의 failureRate는 0.0~1.0 범위로 제한된다")
    func errorSimulationFailureRateIsClampedToValidRange() {
        let underflow = ErrorSimulation(errorType: .timeout, failureRate: -0.5)
        #expect(underflow.failureRate == 0.0)

        let overflow = ErrorSimulation(errorType: .timeout, failureRate: 1.5)
        #expect(overflow.failureRate == 1.0)

        let valid = ErrorSimulation(errorType: .timeout, failureRate: 0.7)
        #expect(valid.failureRate == 0.7)
    }

    @Test("ErrorSimulation의 shouldFail은 failureRate에 따라 동작한다")
    func errorSimulationShouldFailWorksByFailureRate() {
        // failureRate 100% - 항상 실패
        let alwaysFail = ErrorSimulation(errorType: .timeout, failureRate: 1.0)
        var failCount = 0
        for _ in 0 ..< 100 {
            if alwaysFail.shouldFail() {
                failCount += 1
            }
        }
        #expect(failCount == 100)

        // failureRate 0% - 항상 성공
        let neverFail = ErrorSimulation(errorType: .timeout, failureRate: 0.0)
        var successCount = 0
        for _ in 0 ..< 100 {
            if !neverFail.shouldFail() {
                successCount += 1
            }
        }
        #expect(successCount == 100)
    }

    // MARK: - ErrorSimulationAttempt Tests

    @Test("ErrorSimulationAttempt는 성공 시도를 생성할 수 있다")
    func errorSimulationAttemptCanCreateSuccessAttempt() {
        let attempt = ErrorSimulationAttempt(
            attemptNumber: 1,
            success: true,
            delay: 0.5
        )

        #expect(attempt.attemptNumber == 1)
        #expect(attempt.success == true)
        #expect(attempt.error == nil)
        #expect(attempt.errorType == nil)
        #expect(attempt.delay == 0.5)
    }

    @Test("ErrorSimulationAttempt는 실패 시도를 생성할 수 있다")
    func errorSimulationAttemptCanCreateFailureAttempt() {
        let attempt = ErrorSimulationAttempt(
            attemptNumber: 2,
            success: false,
            error: "Network error",
            errorType: .networkFailure,
            delay: 1.0
        )

        #expect(attempt.attemptNumber == 2)
        #expect(attempt.success == false)
        #expect(attempt.error == "Network error")
        #expect(attempt.errorType == .networkFailure)
        #expect(attempt.delay == 1.0)
    }

    @Test("ErrorSimulationAttempt의 formattedTimestamp는 HH:mm:ss.SSS 형식이다")
    func errorSimulationAttemptFormattedTimestampIsFormatted() {
        let attempt = ErrorSimulationAttempt(
            attemptNumber: 1,
            timestamp: Date(),
            success: true
        )

        let formatted = attempt.formattedTimestamp
        // HH:mm:ss.SSS 형식 검증
        #expect(formatted.contains(":"))
        #expect(formatted.count >= 10) // "12:34:56.789"
    }

    @Test("ErrorSimulationAttempt의 formattedDelay는 초 단위 문자열이다")
    func errorSimulationAttemptFormattedDelayIsInSeconds() {
        let attemptWithDelay = ErrorSimulationAttempt(
            attemptNumber: 1,
            success: true,
            delay: 1.234
        )
        #expect(attemptWithDelay.formattedDelay == "1.23초")

        let attemptWithoutDelay = ErrorSimulationAttempt(
            attemptNumber: 1,
            success: true
        )
        #expect(attemptWithoutDelay.formattedDelay == nil)
    }

    // MARK: - ErrorSimulationTimeline Tests

    @Test("ErrorSimulationTimeline은 초기 상태로 생성된다")
    func errorSimulationTimelineCreatesWithInitialState() {
        let timeline = ErrorSimulationTimeline(
            errorType: .timeout,
            failureRate: 0.5,
            maxRetries: 3
        )

        #expect(timeline.errorType == .timeout)
        #expect(timeline.failureRate == 0.5)
        #expect(timeline.maxRetries == 3)
        #expect(timeline.attempts.isEmpty)
        #expect(timeline.endTime == nil)
        #expect(timeline.isCompleted == false)
    }

    @Test("ErrorSimulationTimeline에 시도를 추가할 수 있다")
    func errorSimulationTimelineCanAddAttempts() {
        var timeline = ErrorSimulationTimeline(
            errorType: .timeout,
            failureRate: 0.5,
            maxRetries: 3
        )

        let attempt1 = ErrorSimulationAttempt(attemptNumber: 1, success: false)
        timeline.addAttempt(attempt1)

        #expect(timeline.attempts.count == 1)
        #expect(timeline.isCompleted == false)
    }

    @Test("ErrorSimulationTimeline은 성공 시 완료된다")
    func errorSimulationTimelineCompletesOnSuccess() {
        var timeline = ErrorSimulationTimeline(
            errorType: .timeout,
            failureRate: 0.5,
            maxRetries: 3
        )

        let successAttempt = ErrorSimulationAttempt(attemptNumber: 1, success: true)
        timeline.addAttempt(successAttempt)

        #expect(timeline.isCompleted == true)
        #expect(timeline.endTime != nil)
        #expect(timeline.finalSuccess == true)
    }

    @Test("ErrorSimulationTimeline은 maxRetries 초과 시 완료된다")
    func errorSimulationTimelineCompletesOnMaxRetries() {
        var timeline = ErrorSimulationTimeline(
            errorType: .timeout,
            failureRate: 1.0,
            maxRetries: 2
        )

        timeline.addAttempt(ErrorSimulationAttempt(attemptNumber: 1, success: false))
        timeline.addAttempt(ErrorSimulationAttempt(attemptNumber: 2, success: false))
        timeline.addAttempt(ErrorSimulationAttempt(attemptNumber: 3, success: false))

        #expect(timeline.isCompleted == true)
        #expect(timeline.endTime != nil)
        #expect(timeline.finalSuccess == false)
    }

    @Test("ErrorSimulationTimeline의 successRate는 성공률을 계산한다")
    func errorSimulationTimelineSuccessRateCalculatesCorrectly() {
        var timeline = ErrorSimulationTimeline(
            errorType: .timeout,
            failureRate: 0.5,
            maxRetries: 3
        )

        timeline.addAttempt(ErrorSimulationAttempt(attemptNumber: 1, success: false))
        timeline.addAttempt(ErrorSimulationAttempt(attemptNumber: 2, success: true))
        timeline.addAttempt(ErrorSimulationAttempt(attemptNumber: 3, success: true))

        // 3번 시도 중 2번 성공 = 66.7%
        #expect(timeline.successRate > 0.66)
        #expect(timeline.successRate < 0.67)
    }

    @Test("ErrorSimulationTimeline의 formattedDuration은 초 단위 문자열이다")
    func errorSimulationTimelineFormattedDurationIsInSeconds() {
        let timeline = ErrorSimulationTimeline(
            errorType: .timeout,
            failureRate: 0.5,
            maxRetries: 3
        )

        let formatted = timeline.formattedDuration
        #expect(formatted.contains("초"))
    }
}
