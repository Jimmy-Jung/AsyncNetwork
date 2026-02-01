//
//  NotificationDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created on 2026-02-01.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp

@Suite("NotificationDTO Tests")
struct NotificationDTOTests {
    
    // MARK: - TextNotificationDTO Tests
    
    @Suite("TextNotificationDTO Tests")
    struct TextNotificationDTOTests {
        
        @Test("TextNotificationDTO.mock()이 유효한 데이터를 생성하는지 확인")
        func textNotificationDTOMock() {
            // When
            let mock = TextNotificationDTO.mock()
            
            // Then - 필드 존재만 확인
            #expect(!mock.id.isEmpty)
            #expect(!mock.title.isEmpty)
            #expect(!mock.content.isEmpty)
            #expect(!mock.timestamp.isEmpty)
            
            // 검증
            mock.assertValid()
        }
        
        @Test("TextNotificationDTO.mock()이 매번 다른 값을 생성하는지 확인")
        func textNotificationDTOMockRandomness() {
            // When
            let mock1 = TextNotificationDTO.mock()
            let mock2 = TextNotificationDTO.mock()
            
            // Then - 랜덤이므로 값이 달라야 함
            #expect(mock1.id != mock2.id || mock1.title != mock2.title)
        }
        
        @Test("TextNotificationDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
        func textNotificationDTOMockArray() {
            // When
            let mocks = TextNotificationDTO.mockArray(count: 10)
            
            // Then
            #expect(mocks.count == 10)
            
            // 모든 Mock이 유효한지 확인
            for mock in mocks {
                mock.assertValid()
            }
        }
        
        @Test("TextNotificationDTO.mockArray()가 기본 개수로 생성하는지 확인")
        func textNotificationDTOMockArrayDefaultCount() {
            // When (defaultArrayCount: 5)
            let mocks = TextNotificationDTO.mockArray()
            
            // Then
            #expect(mocks.count == 5)
        }
        
        @Test("TextNotificationDTO.builder()가 커스텀 데이터를 생성하는지 확인")
        func textNotificationDTOBuilder() {
            // Given
            let customTitle = "New Message"
            let customContent = "You have a new message from admin"
            
            // When
            let custom = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: NotificationType.text.rawValue)
                .with(title: customTitle)
                .with(content: customContent)
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            // Then
            #expect(custom.id == "text-001")
            #expect(custom.type == NotificationType.text.rawValue)
            #expect(custom.title == customTitle)
            #expect(custom.content == customContent)
            #expect(custom.isRead == false)
            
            custom.assertValid()
        }
        
        @Test("TextNotificationDTO.builder()가 일부만 커스터마이징하는지 확인")
        func textNotificationDTOBuilderPartial() {
            // When - title만 변경
            let partial = TextNotificationDTO.builder()
                .with(title: "Partial Title")
                .build()
            
            // Then
            #expect(partial.title == "Partial Title")
            #expect(!partial.id.isEmpty) // 나머지는 랜덤 생성
            #expect(!partial.content.isEmpty)
            
            partial.assertValid()
        }
        
        @Test("TextNotificationDTO가 Codable을 준수하는지 확인")
        func textNotificationDTOCodable() throws {
            // Given - Builder로 모든 필드 고정
            let original = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Test")
                .with(content: "Content")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            // When - Encode
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)
            
            // Then - Decode
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(TextNotificationDTO.self, from: data)
            
            #expect(decoded.id == original.id)
            #expect(decoded.type == original.type)
            #expect(decoded.title == original.title)
            #expect(decoded.content == original.content)
            #expect(decoded.timestamp == original.timestamp)
            #expect(decoded.isRead == original.isRead)
        }
        
        @Test("TextNotificationDTO가 Equatable을 준수하는지 확인")
        func textNotificationDTOEquatable() {
            // Given
            let dto1 = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Same")
                .with(content: "Same")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let dto2 = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Same")
                .with(content: "Same")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            // Then
            #expect(dto1 == dto2)
        }
    }
    
    // MARK: - ImageNotificationDTO Tests
    
    @Suite("ImageNotificationDTO Tests")
    struct ImageNotificationDTOTests {
        
        @Test("ImageNotificationDTO.mock()이 유효한 데이터를 생성하는지 확인")
        func imageNotificationDTOMock() {
            // When
            let mock = ImageNotificationDTO.mock()
            
            // Then
            #expect(!mock.id.isEmpty)
            #expect(!mock.title.isEmpty)
            #expect(!mock.imageURL.isEmpty)
            #expect(!mock.thumbnail.isEmpty)
            
            mock.assertValid()
        }
        
        @Test("ImageNotificationDTO.builder()로 커스텀 이미지 URL 설정")
        func imageNotificationDTOBuilderCustom() {
            // Given
            let customImageURL = "https://example.com/images/notification.jpg"
            let customThumbnail = "https://example.com/images/thumbnail.jpg"
            
            // When
            let custom = ImageNotificationDTO.builder()
                .with(id: "image-001")
                .with(type: NotificationType.image.rawValue)
                .with(title: "New Image")
                .with(imageURL: customImageURL)
                .with(thumbnail: customThumbnail)
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            // Then
            #expect(custom.imageURL == customImageURL)
            #expect(custom.thumbnail == customThumbnail)
            
            custom.assertValid()
        }
        
        @Test("ImageNotificationDTO가 Codable을 준수하는지 확인")
        func imageNotificationDTOCodable() throws {
            // Given
            let original = ImageNotificationDTO.builder()
                .with(id: "image-001")
                .with(type: 2)
                .with(title: "Image")
                .with(imageURL: "https://example.com/image.jpg")
                .with(thumbnail: "https://example.com/thumb.jpg")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: true)
                .build()
            
            // When
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(ImageNotificationDTO.self, from: data)
            
            // Then
            #expect(decoded == original)
        }
    }
    
    // MARK: - ActionNotificationDTO Tests
    
    @Suite("ActionNotificationDTO Tests")
    struct ActionNotificationDTOTests {
        
        @Test("ActionNotificationDTO.mock()이 유효한 데이터를 생성하는지 확인")
        func actionNotificationDTOMock() {
            // When
            let mock = ActionNotificationDTO.mock()
            
            // Then
            #expect(!mock.id.isEmpty)
            #expect(!mock.title.isEmpty)
            #expect(!mock.actionType.isEmpty)
            #expect(!mock.actionURL.isEmpty)
            #expect(!mock.expiresAt.isEmpty)
            
            mock.assertValid()
        }
        
        @Test("ActionNotificationDTO.builder()로 특정 액션 타입 설정")
        func actionNotificationDTOBuilderAction() {
            // Given
            let actionType = "deeplink"
            let actionURL = "myapp://notifications/detail?id=123"
            
            // When
            let custom = ActionNotificationDTO.builder()
                .with(id: "action-001")
                .with(type: NotificationType.action.rawValue)
                .with(title: "Action Required")
                .with(actionType: actionType)
                .with(actionURL: actionURL)
                .with(expiresAt: "2026-02-10T23:59:59Z")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            // Then
            #expect(custom.actionType == actionType)
            #expect(custom.actionURL == actionURL)
            
            custom.assertValid()
        }
        
        @Test("ActionNotificationDTO가 Codable을 준수하는지 확인")
        func actionNotificationDTOCodable() throws {
            // Given
            let original = ActionNotificationDTO.builder()
                .with(id: "action-001")
                .with(type: 3)
                .with(title: "Action")
                .with(actionType: "deeplink")
                .with(actionURL: "myapp://action")
                .with(expiresAt: "2026-02-10T23:59:59Z")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            // When
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(ActionNotificationDTO.self, from: data)
            
            // Then
            #expect(decoded == original)
        }
    }
    
    // MARK: - NotificationType Tests
    
    @Suite("NotificationType Tests")
    struct NotificationTypeTests {
        
        @Test("NotificationType의 모든 케이스가 올바른 rawValue를 가지는지 확인")
        func notificationTypeRawValues() {
            // Then
            #expect(NotificationType.text.rawValue == 1)
            #expect(NotificationType.image.rawValue == 2)
            #expect(NotificationType.action.rawValue == 3)
        }
        
        @Test("NotificationType이 rawValue로부터 초기화되는지 확인")
        func notificationTypeInit() {
            // When & Then
            #expect(NotificationType(rawValue: 1) == .text)
            #expect(NotificationType(rawValue: 2) == .image)
            #expect(NotificationType(rawValue: 3) == .action)
            #expect(NotificationType(rawValue: 999) == nil)
        }
        
        @Test("NotificationType이 CaseIterable을 준수하는지 확인")
        func notificationTypeCaseIterable() {
            // When
            let allCases = NotificationType.allCases
            
            // Then
            #expect(allCases.count == 3)
            #expect(allCases.contains(.text))
            #expect(allCases.contains(.image))
            #expect(allCases.contains(.action))
        }
    }
    
    // MARK: - NotificationDTO Union Type Tests
    
    @Suite("NotificationDTO Union Type Tests")
    struct NotificationDTOUnionTypeTests {
        
        @Test("NotificationDTO.mock()이 유효한 케이스를 생성하는지 확인")
        func notificationDTOMock() throws {
            // When
            let mock = NotificationDTO.mock()
            
            // Then - 각 케이스별 검증
            switch mock {
            case let .text(dto):
                try dto.assertValid()
            case let .image(dto):
                try dto.assertValid()
            case let .action(dto):
                try dto.assertValid()
            }
        }
        
        @Test("NotificationDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
        func notificationDTOMockArray() throws {
            // When
            let mocks = NotificationDTO.mockArray(count: 10)
            
            // Then
            #expect(mocks.count == 10)
            
            // 모든 Mock이 유효한지 확인
            for mock in mocks {
                try mock.assertValid()
            }
        }
        
        @Test("NotificationDTO가 text 케이스를 올바르게 디코딩하는지 확인")
        func notificationDTODecodeText() throws {
            // Given - JSON 문자열
            let json = """
            {
                "id": "text-001",
                "type": 1,
                "title": "Test Title",
                "content": "Test Content",
                "timestamp": "2026-02-01T10:00:00Z",
                "isRead": false
            }
            """
            let data = Data(json.utf8)
            
            // When
            let decoded = try JSONDecoder().decode(NotificationDTO.self, from: data)
            
            // Then
            guard case let .text(textDTO) = decoded else {
                Issue.record("Expected .text case")
                return
            }
            
            #expect(textDTO.id == "text-001")
            #expect(textDTO.type == 1)
            #expect(textDTO.title == "Test Title")
            #expect(textDTO.content == "Test Content")
        }
        
        @Test("NotificationDTO가 image 케이스를 올바르게 디코딩하는지 확인")
        func notificationDTODecodeImage() throws {
            // Given
            let json = """
            {
                "id": "image-001",
                "type": 2,
                "title": "Image Title",
                "imageURL": "https://example.com/image.jpg",
                "thumbnail": "https://example.com/thumb.jpg",
                "timestamp": "2026-02-01T10:00:00Z",
                "isRead": true
            }
            """
            let data = Data(json.utf8)
            
            // When
            let decoded = try JSONDecoder().decode(NotificationDTO.self, from: data)
            
            // Then
            guard case let .image(imageDTO) = decoded else {
                Issue.record("Expected .image case")
                return
            }
            
            #expect(imageDTO.id == "image-001")
            #expect(imageDTO.type == 2)
            #expect(imageDTO.imageURL == "https://example.com/image.jpg")
        }
        
        @Test("NotificationDTO가 action 케이스를 올바르게 디코딩하는지 확인")
        func notificationDTODecodeAction() throws {
            // Given
            let json = """
            {
                "id": "action-001",
                "type": 3,
                "title": "Action Title",
                "actionType": "deeplink",
                "actionURL": "myapp://action",
                "expiresAt": "2026-02-10T23:59:59Z",
                "timestamp": "2026-02-01T10:00:00Z",
                "isRead": false
            }
            """
            let data = Data(json.utf8)
            
            // When
            let decoded = try JSONDecoder().decode(NotificationDTO.self, from: data)
            
            // Then
            guard case let .action(actionDTO) = decoded else {
                Issue.record("Expected .action case")
                return
            }
            
            #expect(actionDTO.id == "action-001")
            #expect(actionDTO.type == 3)
            #expect(actionDTO.actionType == "deeplink")
        }
        
        @Test("NotificationDTO가 알 수 없는 타입으로 디코딩 실패하는지 확인")
        func notificationDTODecodeUnknownType() {
            // Given - 잘못된 type 값
            let invalidJSON = """
            {
                "id": "unknown-001",
                "type": 999,
                "title": "Unknown Type"
            }
            """
            let data = Data(invalidJSON.utf8)
            
            // When & Then
            #expect(throws: DecodingError.self) {
                _ = try JSONDecoder().decode(NotificationDTO.self, from: data)
            }
        }
        
        @Test("NotificationDTO가 각 케이스를 올바르게 인코딩하는지 확인")
        func notificationDTOEncode() throws {
            // Given - 각 케이스별 DTO 생성
            let textDTO = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Text")
                .with(content: "Content")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let notificationDTO = NotificationDTO.text(textDTO)
            
            // When - Encode
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(notificationDTO)
            
            // Then - Decode back
            let decoded = try JSONDecoder().decode(NotificationDTO.self, from: data)
            
            guard case let .text(decodedText) = decoded else {
                Issue.record("Expected .text case")
                return
            }
            
            #expect(decodedText.id == textDTO.id)
            #expect(decodedText.title == textDTO.title)
        }
        
        @Test("NotificationDTO가 Equatable을 준수하는지 확인")
        func notificationDTOEquatable() {
            // Given - 동일한 text notification 두 개
            let textDTO1 = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Same")
                .with(content: "Same")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let textDTO2 = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Same")
                .with(content: "Same")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let notification1 = NotificationDTO.text(textDTO1)
            let notification2 = NotificationDTO.text(textDTO2)
            
            // Then
            #expect(notification1 == notification2)
            
            // Given - 다른 케이스
            let imageDTO = ImageNotificationDTO.builder()
                .with(id: "image-001")
                .with(type: 2)
                .with(title: "Image")
                .with(imageURL: "https://example.com/image.jpg")
                .with(thumbnail: "https://example.com/thumb.jpg")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let notification3 = NotificationDTO.image(imageDTO)
            
            // Then - 다른 케이스는 같지 않음
            #expect(notification1 != notification3)
        }
        
        @Test("NotificationDTO 배열을 필터링할 수 있는지 확인")
        func notificationDTOArrayFiltering() {
            // Given - 여러 타입의 notification
            let textDTO = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Text")
                .with(content: "Content")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let imageDTO = ImageNotificationDTO.builder()
                .with(id: "image-001")
                .with(type: 2)
                .with(title: "Image")
                .with(imageURL: "https://example.com/image.jpg")
                .with(thumbnail: "https://example.com/thumb.jpg")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: false)
                .build()
            
            let notifications: [NotificationDTO] = [
                .text(textDTO),
                .image(imageDTO),
                .text(textDTO)
            ]
            
            // When - text 타입만 필터링
            let textNotifications = notifications.filter {
                if case .text = $0 { return true }
                return false
            }
            
            // Then
            #expect(textNotifications.count == 2)
        }
        
        @Test("NotificationDTO가 읽지 않은 알림만 필터링할 수 있는지 확인")
        func notificationDTOUnreadFiltering() {
            // Given
            let read = TextNotificationDTO.builder()
                .with(id: "text-001")
                .with(type: 1)
                .with(title: "Read")
                .with(content: "Content")
                .with(timestamp: "2026-02-01T10:00:00Z")
                .with(isRead: true)
                .build()
            
            let unread = TextNotificationDTO.builder()
                .with(id: "text-002")
                .with(type: 1)
                .with(title: "Unread")
                .with(content: "Content")
                .with(timestamp: "2026-02-01T11:00:00Z")
                .with(isRead: false)
                .build()
            
            let notifications: [NotificationDTO] = [
                .text(read),
                .text(unread)
            ]
            
            // When - 읽지 않은 알림만 필터링
            let unreadNotifications = notifications.filter { notification in
                switch notification {
                case let .text(dto):
                    return !dto.isRead
                case let .image(dto):
                    return !dto.isRead
                case let .action(dto):
                    return !dto.isRead
                }
            }
            
            // Then
            #expect(unreadNotifications.count == 1)
        }
    }
}
