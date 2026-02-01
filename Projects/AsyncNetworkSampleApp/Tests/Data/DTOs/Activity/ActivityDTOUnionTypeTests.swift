//
//  ActivityDTOUnionTypeTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("ActivityDTO Union Type Tests")
struct ActivityDTOUnionTypeTests {
    @Test("ActivityDTO.mock()이 유효한 케이스를 생성하는지 확인")
    func activityDTOMock() throws {
        let mock = ActivityDTO.mock()

        switch mock {
        case let .login(dto):
            try dto.assertValid()
        case let .purchase(dto):
            try dto.assertValid()
        case let .view(dto):
            try dto.assertValid()
        }
    }

    @Test("ActivityDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func activityDTOMockArray() throws {
        let mocks = ActivityDTO.mockArray(count: 10)

        #expect(mocks.count == 10)

        for mock in mocks {
            try mock.assertValid()
        }
    }

    @Test("ActivityDTO가 login 케이스를 올바르게 디코딩하는지 확인")
    func activityDTODecodeLogin() throws {
        let json = """
        {
            "id": "login-001",
            "type": "login",
            "userId": "user-123",
            "deviceInfo": "iPhone 15 Pro",
            "ipAddress": "192.168.1.100",
            "timestamp": "2026-02-01T10:00:00Z"
        }
        """
        let data = Data(json.utf8)

        let decoded = try JSONDecoder().decode(ActivityDTO.self, from: data)

        guard case let .login(loginDTO) = decoded else {
            Issue.record("Expected .login case")
            return
        }

        #expect(loginDTO.id == "login-001")
        #expect(loginDTO.type == "login")
        #expect(loginDTO.userId == "user-123")
        #expect(loginDTO.ipAddress == "192.168.1.100")
    }

    @Test("ActivityDTO가 purchase 케이스를 올바르게 디코딩하는지 확인")
    func activityDTODecodePurchase() throws {
        let json = """
        {
            "id": "purchase-001",
            "type": "purchase",
            "userId": "user-123",
            "productId": "prod-premium",
            "productName": "Premium Subscription",
            "amount": 9.99,
            "currency": "USD",
            "timestamp": "2026-02-01T10:00:00Z"
        }
        """
        let data = Data(json.utf8)

        let decoded = try JSONDecoder().decode(ActivityDTO.self, from: data)

        guard case let .purchase(purchaseDTO) = decoded else {
            Issue.record("Expected .purchase case")
            return
        }

        #expect(purchaseDTO.id == "purchase-001")
        #expect(purchaseDTO.type == "purchase")
        #expect(purchaseDTO.productName == "Premium Subscription")
        #expect(purchaseDTO.amount == 9.99)
    }

    @Test("ActivityDTO가 view 케이스를 올바르게 디코딩하는지 확인")
    func activityDTODecodeView() throws {
        let json = """
        {
            "id": "view-001",
            "type": "view",
            "userId": "user-123",
            "contentId": "content-456",
            "contentType": "video",
            "duration": 3600,
            "timestamp": "2026-02-01T10:00:00Z"
        }
        """
        let data = Data(json.utf8)

        let decoded = try JSONDecoder().decode(ActivityDTO.self, from: data)

        guard case let .view(viewDTO) = decoded else {
            Issue.record("Expected .view case")
            return
        }

        #expect(viewDTO.id == "view-001")
        #expect(viewDTO.type == "view")
        #expect(viewDTO.contentType == "video")
        #expect(viewDTO.duration == 3600)
    }

    @Test("ActivityDTO가 알 수 없는 타입으로 디코딩 실패하는지 확인")
    func activityDTODecodeUnknownType() {
        let invalidJSON = """
        {
            "id": "unknown-001",
            "type": "unknown",
            "userId": "user-123"
        }
        """
        let data = Data(invalidJSON.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(ActivityDTO.self, from: data)
        }
    }

    @Test("ActivityDTO가 Equatable을 준수하는지 확인")
    func activityDTOEquatable() {
        let loginDTO1 = LoginActivityDTO.builder()
            .with(id: "login-001")
            .with(type: "login")
            .with(userId: "user-123")
            .with(deviceInfo: "iPhone")
            .with(ipAddress: "192.168.1.1")
            .with(timestamp: "2026-02-01T10:00:00Z")
            .build()

        let loginDTO2 = LoginActivityDTO.builder()
            .with(id: "login-001")
            .with(type: "login")
            .with(userId: "user-123")
            .with(deviceInfo: "iPhone")
            .with(ipAddress: "192.168.1.1")
            .with(timestamp: "2026-02-01T10:00:00Z")
            .build()

        let activity1 = ActivityDTO.login(loginDTO1)
        let activity2 = ActivityDTO.login(loginDTO2)

        #expect(activity1 == activity2)
    }
}
