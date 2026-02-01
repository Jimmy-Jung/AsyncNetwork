//
//  ActivityDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("ActivityDTO Tests - Bug Reproduction")
struct ActivityDTOTests {
    // MARK: - LoginActivityDTO Tests

    @Suite("LoginActivityDTO Tests")
    struct LoginActivityDTOTests {
        @Test("LoginActivityDTO.mock()이 유효한 데이터를 생성하는지 확인")
        func loginActivityDTOMock() {
            let mock = LoginActivityDTO.mock()

            #expect(!mock.id.isEmpty)
            #expect(!mock.userId.isEmpty)
            #expect(!mock.deviceInfo.isEmpty)
            #expect(!mock.ipAddress.isEmpty)

            mock.assertValid()
        }

        @Test("LoginActivityDTO.builder()로 특정 IP 주소 설정")
        func loginActivityDTOBuilderCustomIP() {
            let customIP = "192.168.1.100"
            let customDevice = "iPhone 15 Pro"

            let custom = LoginActivityDTO.builder()
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

    // MARK: - PurchaseActivityDTO Tests

    @Suite("PurchaseActivityDTO Tests")
    struct PurchaseActivityDTOTests {
        @Test("PurchaseActivityDTO.mock()이 유효한 데이터를 생성하는지 확인")
        func purchaseActivityDTOMock() {
            let mock = PurchaseActivityDTO.mock()

            #expect(!mock.id.isEmpty)
            #expect(!mock.userId.isEmpty)
            #expect(!mock.productId.isEmpty)
            #expect(!mock.productName.isEmpty)
            #expect(mock.amount > 0)

            mock.assertValid()
        }

        @Test("PurchaseActivityDTO.builder()로 특정 구매 정보 설정")
        func purchaseActivityDTOBuilderCustom() {
            let productName = "Premium Subscription"
            let amount = 9.99
            let currency = "USD"

            let custom = PurchaseActivityDTO.builder()
                .with(id: "purchase-001")
                .with(type: ActivityType.purchase.rawValue)
                .with(userId: "user-123")
                .with(productId: "prod-premium")
                .with(productName: productName)
                .with(amount: amount)
                .with(currency: currency)
                .with(timestamp: "2026-02-01T10:00:00Z")
                .build()

            #expect(custom.productName == productName)
            #expect(custom.amount == amount)
            #expect(custom.currency == currency)

            custom.assertValid()
        }
    }

    // MARK: - ViewActivityDTO Tests

    @Suite("ViewActivityDTO Tests")
    struct ViewActivityDTOTests {
        @Test("ViewActivityDTO.mock()이 유효한 데이터를 생성하는지 확인")
        func viewActivityDTOMock() {
            let mock = ViewActivityDTO.mock()

            #expect(!mock.id.isEmpty)
            #expect(!mock.userId.isEmpty)
            #expect(!mock.contentId.isEmpty)
            #expect(!mock.contentType.isEmpty)
            #expect(mock.duration >= 0)

            mock.assertValid()
        }

        @Test("ViewActivityDTO.builder()로 특정 조회 정보 설정")
        func viewActivityDTOBuilderCustom() {
            let contentType = "video"
            let duration = 3600

            let custom = ViewActivityDTO.builder()
                .with(id: "view-001")
                .with(type: ActivityType.view.rawValue)
                .with(userId: "user-123")
                .with(contentId: "content-456")
                .with(contentType: contentType)
                .with(duration: duration)
                .with(timestamp: "2026-02-01T10:00:00Z")
                .build()

            #expect(custom.contentType == contentType)
            #expect(custom.duration == duration)

            custom.assertValid()
        }
    }

    // MARK: - ActivityType Tests

    @Suite("ActivityType Tests")
    struct ActivityTypeTests {
        @Test("ActivityType의 모든 케이스가 올바른 rawValue를 가지는지 확인")
        func activityTypeRawValues() {
            #expect(ActivityType.login.rawValue == "login")
            #expect(ActivityType.purchase.rawValue == "purchase")
            #expect(ActivityType.view.rawValue == "view")
        }

        @Test("ActivityType이 rawValue로부터 초기화되는지 확인")
        func activityTypeInit() {
            #expect(ActivityType(rawValue: "login") == .login)
            #expect(ActivityType(rawValue: "purchase") == .purchase)
            #expect(ActivityType(rawValue: "view") == .view)
            #expect(ActivityType(rawValue: "unknown") == nil)
        }

        @Test("ActivityType이 CaseIterable을 준수하는지 확인")
        func activityTypeCaseIterable() {
            let allCases = ActivityType.allCases

            #expect(allCases.count == 3)
            #expect(allCases.contains(.login))
            #expect(allCases.contains(.purchase))
            #expect(allCases.contains(.view))
        }
    }

    // MARK: - ActivityDTO Union Type Tests

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

    // MARK: - ActivityFeedResponseDTO Tests (버그 재현)

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
}
