//
//  ActivityFeedResponseDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("ActivityFeedResponseDTO Tests - Bug Reproduction")
struct ActivityFeedResponseDTOTests {
    @Test("ActivityFeedResponseDTO.builder()가 enum 배열을 올바르게 생성하는지 확인")
    func activityFeedResponseDTOBuilderBugFixed() {
        let response = ActivityFeedResponseDTO.builder().build()

        #expect(response.totalCount == 1)
        #expect(response.activities.count == 5)

        for activity in response.activities {
            switch activity {
            case let .login(dto):
                #expect(!dto.id.isEmpty)
                #expect(!dto.type.isEmpty)
                #expect(!dto.userId.isEmpty)
                #expect(!dto.timestamp.isEmpty)
            case let .purchase(dto):
                #expect(!dto.id.isEmpty)
                #expect(!dto.type.isEmpty)
                #expect(!dto.userId.isEmpty)
                #expect(!dto.timestamp.isEmpty)
            case let .view(dto):
                #expect(!dto.id.isEmpty)
                #expect(!dto.type.isEmpty)
                #expect(!dto.userId.isEmpty)
                #expect(!dto.timestamp.isEmpty)
            }
        }

        response.assertValid()
    }

    @Test("ActivityFeedResponseDTO.builder()로 커스텀 activities를 설정할 수 있는지 확인")
    func activityFeedResponseDTOBuilderWithCustomActivities() {
        let loginActivity = ActivityDTO.login(
            LoginActivityDTO.builder()
                .with(id: "login-001")
                .with(type: ActivityType.login.rawValue)
                .with(userId: "user-123")
                .with(deviceInfo: "iPhone")
                .with(ipAddress: "192.168.1.1")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .build()
        )

        let purchaseActivity = ActivityDTO.purchase(
            PurchaseActivityDTO.builder()
                .with(id: "purchase-001")
                .with(type: ActivityType.purchase.rawValue)
                .with(userId: "user-123")
                .with(productId: "prod-001")
                .with(productName: "Item")
                .with(amount: 9.99)
                .with(currency: "USD")
                .with(timestamp: "2026-02-01T11:00:00Z")
                .build()
        )

        let response = ActivityFeedResponseDTO.builder()
            .with(totalCount: 2)
            .with(activities: [loginActivity, purchaseActivity])
            .build()

        #expect(response.totalCount == 2)
        #expect(response.activities.count == 2)

        if case let .login(dto) = response.activities[0] {
            #expect(dto.id == "login-001")
            #expect(dto.userId == "user-123")
        } else {
            Issue.record("First activity should be login")
        }

        if case let .purchase(dto) = response.activities[1] {
            #expect(dto.id == "purchase-001")
            #expect(dto.userId == "user-123")
        } else {
            Issue.record("Second activity should be purchase")
        }

        response.assertValid()
    }

    @Test("ActivityFeedResponseDTO.mock()이 유효한 데이터를 생성하는지 확인")
    func activityFeedResponseDTOMock() {
        let mock = ActivityFeedResponseDTO.mock()

        #expect(mock.totalCount > 0)
        #expect(mock.activities.count == 5)

        for activity in mock.activities {
            switch activity {
            case let .login(dto):
                #expect(!dto.id.isEmpty)
                #expect(!dto.type.isEmpty)
                #expect(!dto.userId.isEmpty)
                #expect(!dto.timestamp.isEmpty)
            case let .purchase(dto):
                #expect(!dto.id.isEmpty)
                #expect(!dto.type.isEmpty)
                #expect(!dto.userId.isEmpty)
                #expect(!dto.timestamp.isEmpty)
            case let .view(dto):
                #expect(!dto.id.isEmpty)
                #expect(!dto.type.isEmpty)
                #expect(!dto.userId.isEmpty)
                #expect(!dto.timestamp.isEmpty)
            }
        }

        mock.assertValid()
    }

    @Test("ActivityFeedResponseDTO.mockArray()가 여러 개를 생성하는지 확인")
    func activityFeedResponseDTOMockArray() {
        let mocks = ActivityFeedResponseDTO.mockArray(count: 5)

        #expect(mocks.count == 5)

        for mock in mocks {
            #expect(mock.totalCount > 0)
            #expect(!mock.activities.isEmpty)
            mock.assertValid()
        }
    }

    @Test("ActivityFeedResponseDTO를 수동으로 생성할 수 있는지 확인")
    func activityFeedResponseDTOManualCreation() {
        let loginActivity = ActivityDTO.login(
            LoginActivityDTO.builder()
                .with(id: "login-001")
                .with(type: "login")
                .with(userId: "user-123")
                .with(deviceInfo: "iPhone")
                .with(ipAddress: "192.168.1.1")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .build()
        )

        let purchaseActivity = ActivityDTO.purchase(
            PurchaseActivityDTO.builder()
                .with(id: "purchase-001")
                .with(type: "purchase")
                .with(userId: "user-123")
                .with(productId: "prod-001")
                .with(productName: "Item")
                .with(amount: 9.99)
                .with(currency: "USD")
                .with(timestamp: "2026-02-01T11:00:00Z")
                .build()
        )

        let response = ActivityFeedResponseDTO(
            totalCount: 2,
            activities: [loginActivity, purchaseActivity]
        )

        #expect(response.totalCount == 2)
        #expect(response.activities.count == 2)

        response.assertValid()
    }

    @Test("ActivityFeedResponseDTO가 Codable을 준수하는지 확인")
    func activityFeedResponseDTOCodable() throws {
        let loginActivity = ActivityDTO.login(
            LoginActivityDTO.builder()
                .with(id: "login-001")
                .with(type: ActivityType.login.rawValue)
                .with(userId: "user-123")
                .with(deviceInfo: "iPhone")
                .with(ipAddress: "192.168.1.1")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .build()
        )

        let purchaseActivity = ActivityDTO.purchase(
            PurchaseActivityDTO.builder()
                .with(id: "purchase-001")
                .with(type: ActivityType.purchase.rawValue)
                .with(userId: "user-123")
                .with(productId: "prod-001")
                .with(productName: "Item")
                .with(amount: 9.99)
                .with(currency: "USD")
                .with(timestamp: "2026-02-01T11:00:00Z")
                .build()
        )

        let original = ActivityFeedResponseDTO(
            totalCount: 2,
            activities: [loginActivity, purchaseActivity]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ActivityFeedResponseDTO.self, from: data)

        #expect(decoded.totalCount == original.totalCount)
        #expect(decoded.activities.count == original.activities.count)
    }
}
