//
//  SettingsTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

@testable import AsyncNetworkSampleApp
import Testing

/// Settings 도메인 모델 테스트
@Suite("Settings 도메인 모델")
struct SettingsTests {
    // MARK: - NetworkConfigurationPreset Tests

    @Test("NetworkConfigurationPreset은 모든 프리셋을 제공한다")
    func networkConfigurationPresetProvidesAllPresets() {
        let presets = NetworkConfigurationPreset.allCases

        #expect(presets.count == 5)
        #expect(presets.contains(.development))
        #expect(presets.contains(.default))
        #expect(presets.contains(.stable))
        #expect(presets.contains(.fast))
        #expect(presets.contains(.test))
    }

    @Test("NetworkConfigurationPreset의 displayName은 명확하다")
    func networkConfigurationPresetDisplayNamesAreClear() {
        #expect(NetworkConfigurationPreset.development.displayName == "Development")
        #expect(NetworkConfigurationPreset.default.displayName == "Default")
        #expect(NetworkConfigurationPreset.stable.displayName == "Stable")
        #expect(NetworkConfigurationPreset.fast.displayName == "Fast")
        #expect(NetworkConfigurationPreset.test.displayName == "Test")
    }

    @Test("NetworkConfigurationPreset의 description은 상세 정보를 제공한다")
    func networkConfigurationPresetDescriptionsProvideDetails() {
        #expect(NetworkConfigurationPreset.development.description.contains("재시도"))
        #expect(NetworkConfigurationPreset.default.description.contains("일반"))
        #expect(NetworkConfigurationPreset.stable.description.contains("안정"))
        #expect(NetworkConfigurationPreset.fast.description.contains("빠른"))
        #expect(NetworkConfigurationPreset.test.description.contains("테스트"))
    }

    // MARK: - RetryPolicyPreset Tests

    @Test("RetryPolicyPreset은 모든 프리셋을 제공한다")
    func retryPolicyPresetProvidesAllPresets() {
        let presets = RetryPolicyPreset.allCases

        #expect(presets.count == 3)
        #expect(presets.contains(.default))
        #expect(presets.contains(.aggressive))
        #expect(presets.contains(.conservative))
    }

    @Test("RetryPolicyPreset의 displayName은 명확하다")
    func retryPolicyPresetDisplayNamesAreClear() {
        #expect(RetryPolicyPreset.default.displayName == "Default")
        #expect(RetryPolicyPreset.aggressive.displayName == "Aggressive")
        #expect(RetryPolicyPreset.conservative.displayName == "Conservative")
    }

    @Test("RetryPolicyPreset의 maxRetries는 올바른 값을 반환한다")
    func retryPolicyPresetReturnsCorrectMaxRetries() {
        #expect(RetryPolicyPreset.default.maxRetries == 3)
        #expect(RetryPolicyPreset.aggressive.maxRetries == 5)
        #expect(RetryPolicyPreset.conservative.maxRetries == 1)
    }

    // MARK: - LoggingLevel Tests

    @Test("LoggingLevel은 모든 레벨을 제공한다")
    func loggingLevelProvidesAllLevels() {
        let levels = LoggingLevel.allCases

        #expect(levels.count == 4)
        #expect(levels.contains(.verbose))
        #expect(levels.contains(.info))
        #expect(levels.contains(.error))
        #expect(levels.contains(.none))
    }

    @Test("LoggingLevel의 displayName은 명확하다")
    func loggingLevelDisplayNamesAreClear() {
        #expect(LoggingLevel.verbose.displayName == "Verbose")
        #expect(LoggingLevel.info.displayName == "Info")
        #expect(LoggingLevel.error.displayName == "Error")
        #expect(LoggingLevel.none.displayName == "None")
    }

    // MARK: - NetworkStatus Tests

    @Test("NetworkStatus는 연결 타입을 올바르게 표현한다")
    func networkStatusRepresentsConnectionTypeCorrectly() {
        #expect(NetworkStatus.connected(.wifi).displayName == "Connected")
        #expect(NetworkStatus.connected(.cellular).displayName == "Connected")
        #expect(NetworkStatus.disconnected.displayName == "Disconnected")
    }

    @Test("NetworkStatus는 연결 타입 설명을 제공한다")
    func networkStatusProvidesConnectionTypeDescription() {
        #expect(NetworkStatus.connected(.wifi).connectionTypeDescription == "Wi-Fi")
        #expect(NetworkStatus.connected(.cellular).connectionTypeDescription == "Cellular")
        #expect(NetworkStatus.connected(.ethernet).connectionTypeDescription == "Ethernet")
        #expect(NetworkStatus.disconnected.connectionTypeDescription == "None")
    }

    @Test("NetworkStatus의 isConnected는 올바른 값을 반환한다")
    func networkStatusIsConnectedReturnsCorrectValue() {
        #expect(NetworkStatus.connected(.wifi).isConnected == true)
        #expect(NetworkStatus.connected(.cellular).isConnected == true)
        #expect(NetworkStatus.disconnected.isConnected == false)
    }
}
