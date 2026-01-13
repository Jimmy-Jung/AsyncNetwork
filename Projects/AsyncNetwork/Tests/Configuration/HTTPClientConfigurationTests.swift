//
//  HTTPClientConfigurationTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/11.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

@Suite("HTTPClientConfiguration 프리셋 테스트")
struct HTTPClientConfigurationTests {
    // MARK: - Default Preset

    @Test("기본 생성자는 일반 API 요청에 적합한 설정")
    func defaultPreset() {
        let config = HTTPClientConfiguration()

        #expect(config.timeoutForRequest == 60.0)
        #expect(config.timeoutForResource == 604_800.0) // 7일
        #expect(config.cachePolicy == .useProtocolCachePolicy)
        #expect(config.allowsCellularAccess == true)
        #expect(config.allowsExpensiveNetworkAccess == true)
        #expect(config.allowsConstrainedNetworkAccess == true)
        #expect(config.waitsForConnectivity == false)
        #expect(config.maxConnectionsPerHost == 6)
        #expect(config.additionalHeaders == nil)
    }

    // MARK: - Image Preset

    @Test("image 프리셋은 이미지 다운로드에 최적화")
    func imagePreset() {
        let config = HTTPClientConfiguration.image

        #expect(config.timeoutForRequest == 30.0)
        #expect(config.timeoutForResource == 300.0) // 5분
        #expect(config.cachePolicy == .useProtocolCachePolicy)
        #expect(config.maxConnectionsPerHost == 4) // 병렬 다운로드 제한
        #expect(config.allowsCellularAccess == true)
        #expect(config.waitsForConnectivity == false)
    }

    @Test("image 프리셋은 일반 프리셋보다 짧은 timeout")
    func imagePresetHasShorterTimeout() {
        let defaultConfig = HTTPClientConfiguration()
        let imageConfig = HTTPClientConfiguration.image

        #expect(imageConfig.timeoutForRequest < defaultConfig.timeoutForRequest)
        #expect(imageConfig.timeoutForResource < defaultConfig.timeoutForResource)
    }

    @Test("image 프리셋은 동시 연결 수 제한")
    func imagePresetLimitsConnections() {
        let defaultConfig = HTTPClientConfiguration()
        let imageConfig = HTTPClientConfiguration.image

        #expect(imageConfig.maxConnectionsPerHost < defaultConfig.maxConnectionsPerHost)
    }

    // MARK: - Upload Preset

    @Test("upload 프리셋은 파일 업로드에 최적화")
    func uploadPreset() {
        let config = HTTPClientConfiguration.upload

        #expect(config.timeoutForRequest == 120.0)
        #expect(config.timeoutForResource == 1800.0) // 30분
        #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(config.allowsCellularAccess == true)
        #expect(config.waitsForConnectivity == false)
    }

    @Test("upload 프리셋은 캐시를 무시")
    func uploadPresetIgnoresCache() {
        let config = HTTPClientConfiguration.upload

        #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test("upload 프리셋은 긴 timeout 제공")
    func uploadPresetHasLongTimeout() {
        let defaultConfig = HTTPClientConfiguration()
        let uploadConfig = HTTPClientConfiguration.upload

        #expect(uploadConfig.timeoutForRequest > defaultConfig.timeoutForRequest)
        #expect(uploadConfig.timeoutForResource < defaultConfig.timeoutForResource) // 7일보다는 짧음
        #expect(uploadConfig.timeoutForResource >= 1800) // 최소 30분
    }

    // MARK: - Download Preset

    @Test("download 프리셋은 대용량 다운로드에 최적화")
    func downloadPreset() {
        let config = HTTPClientConfiguration.download

        #expect(config.timeoutForRequest == 120.0)
        #expect(config.timeoutForResource == 3600.0) // 1시간
        #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(config.waitsForConnectivity == true) // 연결 복구 대기
    }

    @Test("download 프리셋은 네트워크 복구를 대기")
    func downloadPresetWaitsForConnectivity() {
        let defaultConfig = HTTPClientConfiguration()
        let downloadConfig = HTTPClientConfiguration.download

        #expect(defaultConfig.waitsForConnectivity == false)
        #expect(downloadConfig.waitsForConnectivity == true)
    }

    @Test("download 프리셋은 upload보다 긴 timeout")
    func downloadPresetHasLongerTimeoutThanUpload() {
        let uploadConfig = HTTPClientConfiguration.upload
        let downloadConfig = HTTPClientConfiguration.download

        #expect(downloadConfig.timeoutForResource > uploadConfig.timeoutForResource)
    }

    // MARK: - Realtime Preset

    @Test("realtime 프리셋은 실시간 데이터에 최적화")
    func realtimePreset() {
        let config = HTTPClientConfiguration.realtime

        #expect(config.timeoutForRequest == 10.0)
        #expect(config.timeoutForResource == 60.0)
        #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(config.waitsForConnectivity == false)
    }

    @Test("realtime 프리셋은 빠른 응답 시간")
    func realtimePresetHasShortTimeout() {
        let realtimeConfig = HTTPClientConfiguration.realtime

        // realtime은 10초 이하의 짧은 timeout
        #expect(realtimeConfig.timeoutForRequest <= 10)
        #expect(realtimeConfig.timeoutForResource <= 60)

        // default보다는 훨씬 짧음
        let defaultConfig = HTTPClientConfiguration()
        #expect(realtimeConfig.timeoutForRequest < defaultConfig.timeoutForRequest)
    }

    @Test("realtime 프리셋은 캐시를 무시")
    func realtimePresetIgnoresCache() {
        let config = HTTPClientConfiguration.realtime

        #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    // MARK: - Offline Preset

    @Test("offline 프리셋은 오프라인 우선 동작")
    func offlinePreset() {
        let config = HTTPClientConfiguration.offline

        #expect(config.timeoutForRequest == 5.0)
        #expect(config.timeoutForResource == 30.0)
        #expect(config.cachePolicy == .returnCacheDataElseLoad)
        #expect(config.waitsForConnectivity == false)
    }

    @Test("offline 프리셋은 캐시 우선 정책")
    func offlinePresetPrefersCachedData() {
        let config = HTTPClientConfiguration.offline

        #expect(config.cachePolicy == .returnCacheDataElseLoad)
    }

    @Test("offline 프리셋은 매우 짧은 timeout")
    func offlinePresetHasVeryShortTimeout() {
        let defaultConfig = HTTPClientConfiguration()
        let offlineConfig = HTTPClientConfiguration.offline

        #expect(offlineConfig.timeoutForRequest < 10)
        #expect(offlineConfig.timeoutForResource < 60)
        #expect(offlineConfig.timeoutForRequest < defaultConfig.timeoutForRequest)
    }

    // MARK: - WiFi Only Preset

    @Test("wifiOnly 프리셋은 Wi-Fi만 사용")
    func wiFiOnlyPreset() {
        let config = HTTPClientConfiguration.wifiOnly

        #expect(config.allowsCellularAccess == false)
        #expect(config.allowsExpensiveNetworkAccess == false)
        #expect(config.allowsConstrainedNetworkAccess == true)
    }

    @Test("wifiOnly 프리셋은 셀룰러 네트워크 차단")
    func wiFiOnlyPresetBlocksCellular() {
        let defaultConfig = HTTPClientConfiguration()
        let wifiConfig = HTTPClientConfiguration.wifiOnly

        #expect(defaultConfig.allowsCellularAccess == true)
        #expect(wifiConfig.allowsCellularAccess == false)
    }

    @Test("wifiOnly 프리셋은 고비용 네트워크 차단")
    func wiFiOnlyPresetBlocksExpensiveNetworks() {
        let defaultConfig = HTTPClientConfiguration()
        let wifiConfig = HTTPClientConfiguration.wifiOnly

        #expect(defaultConfig.allowsExpensiveNetworkAccess == true)
        #expect(wifiConfig.allowsExpensiveNetworkAccess == false)
    }

    // MARK: - Low Power Preset

    @Test("lowPower 프리셋은 저전력 모드에 최적화")
    func lowPowerPreset() {
        let config = HTTPClientConfiguration.lowPower

        #expect(config.timeoutForRequest == 30.0)
        #expect(config.timeoutForResource == 300.0)
        #expect(config.cachePolicy == .returnCacheDataElseLoad)
        #expect(config.allowsExpensiveNetworkAccess == false)
        #expect(config.allowsConstrainedNetworkAccess == false)
    }

    @Test("lowPower 프리셋은 제한된 네트워크만 사용")
    func lowPowerPresetLimitsNetworkAccess() {
        let defaultConfig = HTTPClientConfiguration()
        let lowPowerConfig = HTTPClientConfiguration.lowPower

        #expect(defaultConfig.allowsExpensiveNetworkAccess == true)
        #expect(lowPowerConfig.allowsExpensiveNetworkAccess == false)

        #expect(defaultConfig.allowsConstrainedNetworkAccess == true)
        #expect(lowPowerConfig.allowsConstrainedNetworkAccess == false)
    }

    @Test("lowPower 프리셋은 캐시 우선 정책")
    func lowPowerPresetPrefersCachedData() {
        let config = HTTPClientConfiguration.lowPower

        #expect(config.cachePolicy == .returnCacheDataElseLoad)
    }

    // MARK: - Preset Comparison

    @Test("모든 프리셋은 고유한 설정 조합")
    func allPresetsHaveUniqueConfigurations() {
        let presets: [(String, HTTPClientConfiguration)] = [
            ("default", HTTPClientConfiguration()),
            ("image", .image),
            ("upload", .upload),
            ("download", .download),
            ("realtime", .realtime),
            ("offline", .offline),
            ("wifiOnly", .wifiOnly),
            ("lowPower", .lowPower)
        ]

        // 각 프리셋이 적어도 하나의 설정에서 다른 프리셋과 다름
        for index1 in 0 ..< presets.count {
            for index2 in (index1 + 1) ..< presets.count {
                let (name1, config1) = presets[index1]
                let (name2, config2) = presets[index2]

                let isDifferent =
                    config1.timeoutForRequest != config2.timeoutForRequest ||
                    config1.timeoutForResource != config2.timeoutForResource ||
                    config1.cachePolicy != config2.cachePolicy ||
                    config1.allowsCellularAccess != config2.allowsCellularAccess ||
                    config1.allowsExpensiveNetworkAccess != config2.allowsExpensiveNetworkAccess ||
                    config1.allowsConstrainedNetworkAccess != config2.allowsConstrainedNetworkAccess ||
                    config1.waitsForConnectivity != config2.waitsForConnectivity ||
                    config1.maxConnectionsPerHost != config2.maxConnectionsPerHost

                #expect(isDifferent, "\(name1)와 \(name2)는 모든 설정이 동일합니다")
            }
        }
    }

    @Test("캐시를 무시하는 프리셋 확인")
    func testCacheIgnoringPresets() {
        let cacheIgnoringPresets: [HTTPClientConfiguration] = [
            .upload,
            .download,
            .realtime
        ]

        for config in cacheIgnoringPresets {
            #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
        }
    }

    @Test("캐시를 우선하는 프리셋 확인")
    func testCachePreferringPresets() {
        let cachePreferringPresets: [HTTPClientConfiguration] = [
            .offline,
            .lowPower
        ]

        for config in cachePreferringPresets {
            #expect(config.cachePolicy == .returnCacheDataElseLoad)
        }
    }

    @Test("네트워크 제한이 있는 프리셋 확인")
    func networkRestrictedPresets() {
        // wifiOnly: 셀룰러 차단
        #expect(HTTPClientConfiguration.wifiOnly.allowsCellularAccess == false)

        // lowPower: 고비용/제한된 네트워크 차단
        #expect(HTTPClientConfiguration.lowPower.allowsExpensiveNetworkAccess == false)
        #expect(HTTPClientConfiguration.lowPower.allowsConstrainedNetworkAccess == false)
    }

    // MARK: - Custom Configuration

    @Test("커스텀 설정 생성 가능")
    func customConfiguration() {
        let custom = HTTPClientConfiguration(
            timeoutForRequest: 15,
            timeoutForResource: 300,
            cachePolicy: .reloadIgnoringLocalCacheData,
            allowsCellularAccess: false,
            allowsExpensiveNetworkAccess: true,
            allowsConstrainedNetworkAccess: false,
            waitsForConnectivity: true,
            maxConnectionsPerHost: 8,
            additionalHeaders: ["X-Custom": "Value"]
        )

        #expect(custom.timeoutForRequest == 15)
        #expect(custom.timeoutForResource == 300)
        #expect(custom.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(custom.allowsCellularAccess == false)
        #expect(custom.allowsExpensiveNetworkAccess == true)
        #expect(custom.allowsConstrainedNetworkAccess == false)
        #expect(custom.waitsForConnectivity == true)
        #expect(custom.maxConnectionsPerHost == 8)
        #expect(custom.additionalHeaders?["X-Custom"] == "Value")
    }

    @Test("기본값으로 커스텀 설정 생성")
    func customConfigurationWithDefaults() {
        let custom = HTTPClientConfiguration(timeoutForRequest: 15)

        #expect(custom.timeoutForRequest == 15)
        #expect(custom.timeoutForResource == 604_800.0) // 기본값
        #expect(custom.cachePolicy == .useProtocolCachePolicy) // 기본값
        #expect(custom.allowsCellularAccess == true) // 기본값
    }

    // MARK: - Use Case Validation

    @Test("각 프리셋은 용도에 맞는 timeout 설정")
    func timeoutSuitabilityForUseCases() {
        // 실시간: 매우 짧음
        #expect(HTTPClientConfiguration.realtime.timeoutForRequest <= 10)

        // 일반 API: 적당함
        #expect(HTTPClientConfiguration().timeoutForRequest >= 30)
        #expect(HTTPClientConfiguration().timeoutForRequest <= 120)

        // 업로드/다운로드: 긴 편
        #expect(HTTPClientConfiguration.upload.timeoutForRequest >= 60)
        #expect(HTTPClientConfiguration.download.timeoutForRequest >= 60)

        // 오프라인: 매우 짧음 (빠른 실패)
        #expect(HTTPClientConfiguration.offline.timeoutForRequest <= 10)
    }

    @Test("resource timeout은 request timeout보다 크거나 같음")
    func resourceTimeoutIsGreaterOrEqualToRequestTimeout() {
        let allPresets: [HTTPClientConfiguration] = [
            HTTPClientConfiguration(), .image, .upload, .download, .realtime, .offline, .wifiOnly, .lowPower
        ]

        for config in allPresets {
            #expect(
                config.timeoutForResource >= config.timeoutForRequest,
                "resource timeout(\(config.timeoutForResource))이 request timeout(\(config.timeoutForRequest))보다 작습니다"
            )
        }
    }
}
