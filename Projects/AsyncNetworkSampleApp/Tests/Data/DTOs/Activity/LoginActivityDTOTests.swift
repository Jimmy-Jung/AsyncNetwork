//
//  LoginActivityDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("LoginActivityDTO Tests")
struct LoginActivityDTOTests {
    @Test("LoginActivityDTO.random()이 유효한 데이터를 생성하는지 확인")
    func loginActivityDTOMock() {
        let mock = LoginActivityDTO.random()

        #expect(!mock.id.isEmpty)
        #expect(!mock.userId.isEmpty)
        #expect(!mock.deviceInfo.isEmpty)
        #expect(!mock.ipAddress.isEmpty)

        mock.assertValid()
    }

    @Test("LoginActivityDTO.fixture()로 특정 IP 주소 설정")
    func loginActivityDTOBuilderCustomIP() {
        let customIP = "192.168.1.100"
        let customDevice = "iPhone 15 Pro"

        let custom = LoginActivityDTO.fixture()
            .with(id: "login-001")
            .with(type: ActivityType.login.rawValue)
            .with(userId: "user-123")
            .with(deviceInfo: customDevice)
            .with(ipAddress: customIP)
            .with(timestamp: "2026-02-01T10:00:00Z")
            .build()

        #expect(custom.ipAddress == customIP)
        #expect(custom.deviceInfo == customDevice)

        custom.assertValid()
    }
}
