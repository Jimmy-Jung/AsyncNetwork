//
//  ActivityDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026-02-01.
//

import AsyncNetwork
import Foundation

// MARK: - ActivityDTO (Union Type)

/// Union 타입의 활동 DTO
///
/// 사용자 활동의 type 필드에 따라 다른 구조체로 디코딩됩니다.
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// type ActivityDto = LoginActivityDto | PurchaseActivityDto | ViewActivityDto;
/// ```
///
/// - Note: @ResponseTestable 매크로로 mock(), mockArray(), assertValid() 자동 생성
/// - Note: ⚠️ 이 타입은 enum이므로 builder()가 생성되지 않습니다
@ResponseTestable(defaultArrayCount: 3)
public enum ActivityDTO: Codable, Sendable, Equatable {
    case login(LoginActivityDTO)
    case purchase(PurchaseActivityDTO)
    case view(ViewActivityDTO)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        guard let activityType = ActivityType(rawValue: type) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown ActivityType: \(type)"
            )
        }

        switch activityType {
        case .login:
            self = try .login(LoginActivityDTO(from: decoder))
        case .purchase:
            self = try .purchase(PurchaseActivityDTO(from: decoder))
        case .view:
            self = try .view(ViewActivityDTO(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .login(dto):
            try dto.encode(to: encoder)
        case let .purchase(dto):
            try dto.encode(to: encoder)
        case let .view(dto):
            try dto.encode(to: encoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

// MARK: - ActivityType

/// 활동 타입 열거형
///
/// Backend 구조:
/// ```typescript
/// enum ActivityType {
///     Login = "login",
///     Purchase = "purchase",
///     View = "view"
/// }
/// ```
public enum ActivityType: String, Codable, Sendable, CaseIterable {
    case login
    case purchase
    case view
}

// MARK: - LoginActivityDTO

/// 로그인 활동 DTO
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface LoginActivityDto {
///     id: string;
///     type: ActivityType.Login;
///     userId: string;
///     deviceInfo: string;
///     ipAddress: string;
///     timestamp: string;
/// }
/// ```
@ResponseTestable(defaultArrayCount: 3)
public struct LoginActivityDTO: Codable, Sendable, Equatable {
    public let id: String
    public let type: String
    public let userId: String
    public let deviceInfo: String
    public let ipAddress: String
    public let timestamp: String

    public init(
        id: String,
        type: String,
        userId: String,
        deviceInfo: String,
        ipAddress: String,
        timestamp: String
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.deviceInfo = deviceInfo
        self.ipAddress = ipAddress
        self.timestamp = timestamp
    }
}

// MARK: - PurchaseActivityDTO

/// 구매 활동 DTO
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface PurchaseActivityDto {
///     id: string;
///     type: ActivityType.Purchase;
///     userId: string;
///     productId: string;
///     productName: string;
///     amount: number;
///     currency: string;
///     timestamp: string;
/// }
/// ```
@ResponseTestable(defaultArrayCount: 3)
public struct PurchaseActivityDTO: Codable, Sendable, Equatable {
    public let id: String
    public let type: String
    public let userId: String
    public let productId: String
    public let productName: String
    public let amount: Double
    public let currency: String
    public let timestamp: String

    public init(
        id: String,
        type: String,
        userId: String,
        productId: String,
        productName: String,
        amount: Double,
        currency: String,
        timestamp: String
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.productId = productId
        self.productName = productName
        self.amount = amount
        self.currency = currency
        self.timestamp = timestamp
    }
}

// MARK: - ViewActivityDTO

/// 조회 활동 DTO
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface ViewActivityDto {
///     id: string;
///     type: ActivityType.View;
///     userId: string;
///     contentId: string;
///     contentType: string;
///     duration: number;
///     timestamp: string;
/// }
/// ```
@ResponseTestable(defaultArrayCount: 3)
public struct ViewActivityDTO: Codable, Sendable, Equatable {
    public let id: String
    public let type: String
    public let userId: String
    public let contentId: String
    public let contentType: String
    public let duration: Int
    public let timestamp: String

    public init(
        id: String,
        type: String,
        userId: String,
        contentId: String,
        contentType: String,
        duration: Int,
        timestamp: String
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.contentId = contentId
        self.contentType = contentType
        self.duration = duration
        self.timestamp = timestamp
    }
}

// MARK: - ActivityFeedResponseDTO (버그 재현용)

/// 활동 피드 응답 DTO
///
/// ⚠️ 이 타입은 버그 재현을 위한 샘플입니다.
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface ActivityFeedResponseDto {
///     totalCount: number;
///     activities: ActivityDto[];
/// }
/// ```
///
/// ## 버그 설명
///
/// `ActivityDTO`는 enum 타입이므로 `builder()` 메서드를 제공하지 않습니다.
/// 하지만 `@ResponseTestable` 매크로가 `ActivityFeedResponseDTO.builder()`의 `init()`을 생성할 때,
/// `activities` 프로퍼티의 기본값으로 `ActivityDTO.builder().build()`를 호출하려고 시도합니다.
///
/// **예상되는 컴파일 오류**:
/// ```
/// Type 'ActivityDTO' has no member 'builder'
/// ```
///
/// ## 매크로가 생성하는 잘못된 코드
///
/// ```swift
/// public init() {
///     self.totalCount = 1
///     self.activities = (0 ..< 3).map { _ in
///         ActivityDTO.builder().build()  // ❌ enum은 builder()가 없음!
///     }
/// }
/// ```
///
/// ## 올바른 코드
///
/// ```swift
/// public init() {
///     self.totalCount = 1
///     self.activities = (0 ..< 3).map { _ in
///         ActivityDTO.mock()  // ✅ enum은 mock()만 사용 가능
///     }
/// }
/// ```
///
/// - Note: @ResponseTestable 매크로로 mock(), builder(), mockArray(), assertValid() 자동 생성
/// - Warning: ⚠️ v1.3.2 버그 - enum 배열 프로퍼티의 builder() 초기화 실패
@ResponseTestable(defaultArrayCount: 5)
public struct ActivityFeedResponseDTO: Codable, Sendable {
    /// 총 활동 개수
    public let totalCount: Int

    /// 활동 목록 (enum 배열 - 버그 재현용)
    public let activities: [ActivityDTO]

    public init(totalCount: Int, activities: [ActivityDTO]) {
        self.totalCount = totalCount
        self.activities = activities
    }
}
