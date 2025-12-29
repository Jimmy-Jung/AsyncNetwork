//
//  RetryRuleTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetwork
import Foundation
import Testing

// MARK: - URLErrorRetryRuleTests

struct URLErrorRetryRuleTests {
    private let rule = URLErrorRetryRule()

    // MARK: - Retryable Errors

    @Test("networkConnectionLost 에러는 재시도 가능")
    func networkConnectionLostIsRetryable() {
        // Given
        let error = URLError(.networkConnectionLost)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("timedOut 에러는 재시도 가능")
    func timedOutIsRetryable() {
        // Given
        let error = URLError(.timedOut)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("cannotFindHost 에러는 재시도 가능")
    func cannotFindHostIsRetryable() {
        // Given
        let error = URLError(.cannotFindHost)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("cannotConnectToHost 에러는 재시도 가능")
    func cannotConnectToHostIsRetryable() {
        // Given
        let error = URLError(.cannotConnectToHost)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("dnsLookupFailed 에러는 재시도 가능")
    func dnsLookupFailedIsRetryable() {
        // Given
        let error = URLError(.dnsLookupFailed)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("notConnectedToInternet 에러는 재시도 가능")
    func notConnectedToInternetIsRetryable() {
        // Given
        let error = URLError(.notConnectedToInternet)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    // MARK: - Non-Retryable Errors

    @Test("badURL 에러는 재시도 불가")
    func badURLIsNotRetryable() {
        // Given
        let error = URLError(.badURL)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    @Test("cancelled 에러는 재시도 불가")
    func cancelledIsNotRetryable() {
        // Given
        let error = URLError(.cancelled)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    @Test("badServerResponse 에러는 재시도 불가")
    func badServerResponseIsNotRetryable() {
        // Given
        let error = URLError(.badServerResponse)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    // MARK: - Non-URLError

    @Test("URLError가 아닌 에러는 nil 반환")
    func nonURLErrorReturnsNil() {
        // Given
        struct CustomError: Error {}
        let error = CustomError()

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == nil)
    }

    @Test("NSError는 nil 반환")
    func nsErrorReturnsNil() {
        // Given
        let error = NSError(domain: "test", code: 1)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == nil)
    }
}

// MARK: - ServerErrorRetryRuleTests

struct ServerErrorRetryRuleTests {
    private let rule = ServerErrorRetryRule()

    // MARK: - Server Errors (Retryable)

    @Test("serverError 500 에러는 재시도 가능")
    func serverError500IsRetryable() {
        // Given
        let error = StatusCodeValidationError.serverError(500, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("serverError 502 에러는 재시도 가능")
    func serverError502IsRetryable() {
        // Given
        let error = StatusCodeValidationError.serverError(502, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    @Test("serverError 503 에러는 재시도 가능")
    func serverError503IsRetryable() {
        // Given
        let error = StatusCodeValidationError.serverError(503, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == true)
    }

    // MARK: - Client Errors (Not Retryable)

    @Test("clientError 400 에러는 재시도 불가")
    func clientError400IsNotRetryable() {
        // Given
        let error = StatusCodeValidationError.clientError(400, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    @Test("clientError 401 에러는 재시도 불가")
    func clientError401IsNotRetryable() {
        // Given
        let error = StatusCodeValidationError.clientError(401, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    @Test("clientError 404 에러는 재시도 불가")
    func clientError404IsNotRetryable() {
        // Given
        let error = StatusCodeValidationError.clientError(404, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    // MARK: - Invalid Status Code Errors (Not Retryable)

    @Test("invalidStatusCode 에러는 재시도 불가")
    func invalidStatusCodeIsNotRetryable() {
        // Given
        let error = StatusCodeValidationError.invalidStatusCode(100, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    // MARK: - Unknown Errors (Not Retryable)

    @Test("unknownError 에러는 재시도 불가")
    func unknownErrorIsNotRetryable() {
        // Given
        let error = StatusCodeValidationError.unknownError(999, nil)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == false)
    }

    // MARK: - Non-StatusCodeValidationError

    @Test("StatusCodeValidationError가 아닌 에러는 nil 반환")
    func nonStatusCodeValidationErrorReturnsNil() {
        // Given
        let error = URLError(.notConnectedToInternet)

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == nil)
    }

    @Test("일반 Error는 nil 반환")
    func genericErrorReturnsNil() {
        // Given
        struct CustomError: Error {}
        let error = CustomError()

        // When
        let result = rule.shouldRetry(error: error)

        // Then
        #expect(result == nil)
    }
}

// MARK: - RetryRule Chain Tests

struct RetryRuleChainTests {
    @Test("URLError와 ServerError 룰 체인 - URLError 매칭")
    func ruleChainURLErrorMatch() {
        // Given
        let rules: [any RetryRule] = [URLErrorRetryRule(), ServerErrorRetryRule()]
        let error = URLError(.timedOut)

        // When
        let result = rules
            .lazy
            .compactMap { $0.shouldRetry(error: error) }
            .first ?? false

        // Then
        #expect(result == true)
    }

    @Test("URLError와 ServerError 룰 체인 - ServerError 매칭")
    func ruleChainServerErrorMatch() {
        // Given
        let rules: [any RetryRule] = [URLErrorRetryRule(), ServerErrorRetryRule()]
        let error = StatusCodeValidationError.serverError(500, nil)

        // When
        let result = rules
            .lazy
            .compactMap { $0.shouldRetry(error: error) }
            .first ?? false

        // Then
        #expect(result == true)
    }

    @Test("URLError와 ServerError 룰 체인 - 매칭 없음")
    func ruleChainNoMatch() {
        // Given
        let rules: [any RetryRule] = [URLErrorRetryRule(), ServerErrorRetryRule()]
        struct CustomError: Error {}
        let error = CustomError()

        // When
        let result = rules
            .lazy
            .compactMap { $0.shouldRetry(error: error) }
            .first ?? false

        // Then
        #expect(result == false)
    }

    @Test("빈 룰 체인")
    func emptyRuleChain() {
        // Given
        let rules: [any RetryRule] = []
        let error = URLError(.timedOut)

        // When
        let result = rules
            .lazy
            .compactMap { $0.shouldRetry(error: error) }
            .first ?? false

        // Then
        #expect(result == false)
    }
}
