//
//  NotificationDTO.swift
//  AsyncNetworkSampleApp
//
//  Created on 2026-01-31.
//

import AsyncNetwork
import Foundation

// MARK: - NotificationDTO (Union Type)

/// Union 타입의 알림 DTO
///
/// 서버에서 받는 알림의 type 필드에 따라 다른 구조체로 디코딩됩니다.
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// type NotificationDto = TextNotificationDto | ImageNotificationDto | ActionNotificationDto;
/// ```
///
/// - Note: @ResponseTestable 매크로로 mock(), mockArray(), assertValid() 자동 생성
@ResponseTestable(defaultArrayCount: 5)
public enum NotificationDTO: Codable, Sendable, Equatable {
    case text(TextNotificationDTO)
    case image(ImageNotificationDTO)
    case action(ActionNotificationDTO)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Int.self, forKey: .type)
        
        guard let notificationType = NotificationType(rawValue: type) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown NotificationType: \(type)"
            )
        }
        
        switch notificationType {
        case .text:
            self = try .text(TextNotificationDTO(from: decoder))
        case .image:
            self = try .image(ImageNotificationDTO(from: decoder))
        case .action:
            self = try .action(ActionNotificationDTO(from: decoder))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .text(dto):
            try dto.encode(to: encoder)
        case let .image(dto):
            try dto.encode(to: encoder)
        case let .action(dto):
            try dto.encode(to: encoder)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
}

// MARK: - NotificationType

/// 알림 타입 열거형
///
/// Backend 구조:
/// ```typescript
/// enum NotificationType {
///     Text = 1,
///     Image = 2,
///     Action = 3
/// }
/// ```
public enum NotificationType: Int, Codable, Sendable, CaseIterable {
    case text = 1
    case image = 2
    case action = 3
}

// MARK: - TextNotificationDTO

/// 텍스트 알림 DTO
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface TextNotificationDto {
///     id: string;
///     type: NotificationType.Text;
///     title: string;
///     content: string;
///     timestamp: string;
///     isRead: boolean;
/// }
/// ```
@ResponseTestable(defaultArrayCount: 5)
public struct TextNotificationDTO: Codable, Sendable, Equatable {
    public let id: String
    public let type: Int
    public let title: String
    public let content: String
    public let timestamp: String
    public let isRead: Bool
    
    public init(
        id: String,
        type: Int,
        title: String,
        content: String,
        timestamp: String,
        isRead: Bool
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// MARK: - ImageNotificationDTO

/// 이미지 알림 DTO
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface ImageNotificationDto {
///     id: string;
///     type: NotificationType.Image;
///     title: string;
///     imageURL: string;
///     thumbnail: string;
///     timestamp: string;
///     isRead: boolean;
/// }
/// ```
@ResponseTestable(defaultArrayCount: 5)
public struct ImageNotificationDTO: Codable, Sendable, Equatable {
    public let id: String
    public let type: Int
    public let title: String
    public let imageURL: String
    public let thumbnail: String
    public let timestamp: String
    public let isRead: Bool
    
    public init(
        id: String,
        type: Int,
        title: String,
        imageURL: String,
        thumbnail: String,
        timestamp: String,
        isRead: Bool
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.imageURL = imageURL
        self.thumbnail = thumbnail
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// MARK: - ActionNotificationDTO

/// 액션 알림 DTO
///
/// Backend 구조 (TypeScript):
/// ```typescript
/// interface ActionNotificationDto {
///     id: string;
///     type: NotificationType.Action;
///     title: string;
///     actionType: string;
///     actionURL: string;
///     expiresAt: string;
///     timestamp: string;
///     isRead: boolean;
/// }
/// ```
@ResponseTestable(defaultArrayCount: 5)
public struct ActionNotificationDTO: Codable, Sendable, Equatable {
    public let id: String
    public let type: Int
    public let title: String
    public let actionType: String
    public let actionURL: String
    public let expiresAt: String
    public let timestamp: String
    public let isRead: Bool
    
    public init(
        id: String,
        type: Int,
        title: String,
        actionType: String,
        actionURL: String,
        expiresAt: String,
        timestamp: String,
        isRead: Bool
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.actionType = actionType
        self.actionURL = actionURL
        self.expiresAt = expiresAt
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
