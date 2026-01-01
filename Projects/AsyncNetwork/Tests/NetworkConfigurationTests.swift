//
//  NetworkConfigurationTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Testing

// MARK: - NetworkConfigurationTests

struct NetworkConfigurationTests {
    // MARK: - Initialization Tests

    @Test("기본 매개변수로 NetworkConfiguration 생성")
    func createNetworkConfigurationWithDefaultParameters() {
        // Given & When
        let config = NetworkConfiguration()

        // Then
        #expect(config.maxRetries == 3)
        #expect(config.retryDelay == 1.0)
        #expect(config.timeout == 30.0)
        #expect(config.enableLogging == true)
    }

    @Test("커스텀 매개변수로 NetworkConfiguration 생성")
    func createNetworkConfigurationWithCustomParameters() {
        // Given & When
        let config = NetworkConfiguration(
            maxRetries: 5,
            retryDelay: 2.0,
            timeout: 60.0,
            enableLogging: false
        )

        // Then
        #expect(config.maxRetries == 5)
        #expect(config.retryDelay == 2.0)
        #expect(config.timeout == 60.0)
        #expect(config.enableLogging == false)
    }

    // MARK: - Preset Configuration Tests

    @Test("기본 설정 프리셋")
    func validateDefaultPreset() {
        // Given & When
        let config = NetworkConfiguration.default

        // Then
        #expect(config.maxRetries == 3)
        #expect(config.retryDelay == 1.0)
        #expect(config.timeout == 30.0)
        #expect(config.enableLogging == true)
    }

    @Test("개발용 설정 프리셋")
    func validateDevelopmentPreset() {
        // Given & When
        let config = NetworkConfiguration.development

        // Then
        #expect(config.maxRetries == 1)
        #expect(config.retryDelay == 0.5)
        #expect(config.timeout == 15.0)
        #expect(config.enableLogging == true)
    }

    @Test("테스트용 설정 프리셋")
    func validateTestPreset() {
        // Given & When
        let config = NetworkConfiguration.test

        // Then
        #expect(config.maxRetries == 0)
        #expect(config.retryDelay == 0)
        #expect(config.timeout == 5.0)
        #expect(config.enableLogging == false)
    }

    @Test("안정성 우선 설정 프리셋")
    func validateStablePreset() {
        // Given & When
        let config = NetworkConfiguration.stable

        // Then
        #expect(config.maxRetries == 5)
        #expect(config.retryDelay == 2.0)
        #expect(config.timeout == 60.0)
        #expect(config.enableLogging == true)
    }

    @Test("속도 우선 설정 프리셋")
    func validateFastPreset() {
        // Given & When
        let config = NetworkConfiguration.fast

        // Then
        #expect(config.maxRetries == 1)
        #expect(config.retryDelay == 0.1)
        #expect(config.timeout == 10.0)
        #expect(config.enableLogging == false)
    }

    // MARK: - Edge Cases Tests

    @Test("0 재시도 횟수 설정")
    func configurationWithZeroRetries() {
        // Given & When
        let config = NetworkConfiguration(
            maxRetries: 0,
            retryDelay: 1.0,
            timeout: 30.0,
            enableLogging: false
        )

        // Then
        #expect(config.maxRetries == 0)
        #expect(config.retryDelay == 1.0)
        #expect(config.timeout == 30.0)
        #expect(config.enableLogging == false)
    }

    @Test("매우 큰 재시도 횟수 설정")
    func configurationWithLargeRetries() {
        // Given & When
        let config = NetworkConfiguration(
            maxRetries: 100,
            retryDelay: 0.1,
            timeout: 120.0,
            enableLogging: true
        )

        // Then
        #expect(config.maxRetries == 100)
        #expect(config.retryDelay == 0.1)
        #expect(config.timeout == 120.0)
        #expect(config.enableLogging == true)
    }

    @Test("0 재시도 지연 시간 설정")
    func configurationWithZeroRetryDelay() {
        // Given & When
        let config = NetworkConfiguration(
            maxRetries: 3,
            retryDelay: 0,
            timeout: 30.0,
            enableLogging: false
        )

        // Then
        #expect(config.maxRetries == 3)
        #expect(config.retryDelay == 0)
        #expect(config.timeout == 30.0)
        #expect(config.enableLogging == false)
    }

    @Test("매우 긴 타임아웃 설정")
    func configurationWithLongTimeout() {
        // Given & When
        let config = NetworkConfiguration(
            maxRetries: 1,
            retryDelay: 1.0,
            timeout: 300.0, // 5분
            enableLogging: false
        )

        // Then
        #expect(config.maxRetries == 1)
        #expect(config.retryDelay == 1.0)
        #expect(config.timeout == 300.0)
        #expect(config.enableLogging == false)
    }

    @Test("매우 짧은 타임아웃 설정")
    func configurationWithShortTimeout() {
        // Given & When
        let config = NetworkConfiguration(
            maxRetries: 1,
            retryDelay: 0.1,
            timeout: 0.5,
            enableLogging: false
        )

        // Then
        #expect(config.maxRetries == 1)
        #expect(config.retryDelay == 0.1)
        #expect(config.timeout == 0.5)
        #expect(config.enableLogging == false)
    }

    // MARK: - Configuration Comparison Tests

    @Test("서로 다른 설정 프리셋 비교")
    func comparePresetConfigurations() {
        // Given
        let defaultConfig = NetworkConfiguration.default
        let testConfig = NetworkConfiguration.test
        let fastConfig = NetworkConfiguration.fast
        let stableConfig = NetworkConfiguration.stable

        // When & Then
        // 재시도 횟수 비교
        #expect(defaultConfig.maxRetries > testConfig.maxRetries)
        #expect(stableConfig.maxRetries > defaultConfig.maxRetries)
        #expect(fastConfig.maxRetries < defaultConfig.maxRetries)

        // 타임아웃 비교
        #expect(stableConfig.timeout > defaultConfig.timeout)
        #expect(testConfig.timeout < defaultConfig.timeout)
        #expect(fastConfig.timeout < defaultConfig.timeout)

        // 로깅 설정 비교
        #expect(defaultConfig.enableLogging == true)
        #expect(testConfig.enableLogging == false)
        #expect(fastConfig.enableLogging == false)
        #expect(stableConfig.enableLogging == true)
    }

    // MARK: - Sendable Conformance Tests

    @Test("Sendable 프로토콜 준수 확인")
    func validateSendableConformance() {
        // Given
        let config = NetworkConfiguration.default

        // When & Then
        // Sendable 프로토콜을 준수하므로 Task에서 사용 가능
        _Concurrency.Task {
            let maxRetries = config.maxRetries
            let timeout = config.timeout

            #expect(maxRetries == 3)
            #expect(timeout == 30.0)
        }
    }

    // MARK: - Real-world Scenario Tests

    @Test("프로덕션 환경 설정")
    func productionEnvironmentConfiguration() {
        // Given & When
        let productionConfig = NetworkConfiguration(
            maxRetries: 3,
            retryDelay: 1.5,
            timeout: 45.0,
            enableLogging: false // 프로덕션에서는 로깅 비활성화
        )

        // Then
        #expect(productionConfig.maxRetries == 3)
        #expect(productionConfig.retryDelay == 1.5)
        #expect(productionConfig.timeout == 45.0)
        #expect(productionConfig.enableLogging == false)
    }

    @Test("디버깅 환경 설정")
    func debuggingEnvironmentConfiguration() {
        // Given & When
        let debugConfig = NetworkConfiguration(
            maxRetries: 1, // 빠른 실패로 디버깅 용이
            retryDelay: 0.1,
            timeout: 10.0, // 짧은 타임아웃으로 빠른 피드백
            enableLogging: true // 상세 로깅 활성화
        )

        // Then
        #expect(debugConfig.maxRetries == 1)
        #expect(debugConfig.retryDelay == 0.1)
        #expect(debugConfig.timeout == 10.0)
        #expect(debugConfig.enableLogging == true)
    }

    @Test("오프라인 테스트 환경 설정")
    func offlineTestEnvironmentConfiguration() {
        // Given & When
        let offlineConfig = NetworkConfiguration(
            maxRetries: 0, // 재시도 없음
            retryDelay: 0,
            timeout: 1.0, // 매우 짧은 타임아웃
            enableLogging: false
        )

        // Then
        #expect(offlineConfig.maxRetries == 0)
        #expect(offlineConfig.retryDelay == 0)
        #expect(offlineConfig.timeout == 1.0)
        #expect(offlineConfig.enableLogging == false)
    }

    @Test("고가용성 환경 설정")
    func highAvailabilityEnvironmentConfiguration() {
        // Given & When
        let haConfig = NetworkConfiguration(
            maxRetries: 10, // 많은 재시도
            retryDelay: 0.5, // 빠른 재시도
            timeout: 120.0, // 긴 타임아웃
            enableLogging: true
        )

        // Then
        #expect(haConfig.maxRetries == 10)
        #expect(haConfig.retryDelay == 0.5)
        #expect(haConfig.timeout == 120.0)
        #expect(haConfig.enableLogging == true)
    }
}
