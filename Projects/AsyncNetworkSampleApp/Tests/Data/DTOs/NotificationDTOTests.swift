//
//  NotificationDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created on 2026-01-31.
//

import Testing
import Foundation
@testable import AsyncNetworkSampleApp

// MARK: - NotificationDTO Tests

@Suite("NotificationDTO Tests")
struct NotificationDTOTests {
    
    // MARK: - Decoding Tests
    
    @Test("Union 타입 디코딩 - TextNotification")
    func testDecodeTextNotification() throws {
        let json = """
        {
            "id": "notif_123",
            "type": 1,
            "title": "New Message",
            "content": "You have a new message from John",
            "timestamp": "2026-01-31T10:30:00Z",
            "isRead": false
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        let dto = try JSONDecoder().decode(NotificationDTO.self, from: data)
        
        guard case let .text(textNotification) = dto else {
            Issue.record("Expected text notification but got different type")
            return
        }
        
        #expect(textNotification.id == "notif_123")
        #expect(textNotification.type == 1)
        #expect(textNotification.title == "New Message")
        #expect(textNotification.content == "You have a new message from John")
        #expect(textNotification.isRead == false)
    }
    
    @Test("Union 타입 디코딩 - ImageNotification")
    func testDecodeImageNotification() throws {
        let json = """
        {
            "id": "notif_456",
            "type": 2,
            "title": "Photo Update",
            "imageURL": "https://example.com/photo.jpg",
            "thumbnail": "https://example.com/thumb.jpg",
            "timestamp": "2026-01-31T11:00:00Z",
            "isRead": false
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        let dto = try JSONDecoder().decode(NotificationDTO.self, from: data)
        
        guard case let .image(imageNotification) = dto else {
            Issue.record("Expected image notification but got different type")
            return
        }
        
        #expect(imageNotification.id == "notif_456")
        #expect(imageNotification.type == 2)
        #expect(imageNotification.title == "Photo Update")
        #expect(imageNotification.imageURL == "https://example.com/photo.jpg")
        #expect(imageNotification.thumbnail == "https://example.com/thumb.jpg")
        #expect(imageNotification.isRead == false)
    }
    
    @Test("Union 타입 디코딩 - ActionNotification")
    func testDecodeActionNotification() throws {
        let json = """
        {
            "id": "notif_789",
            "type": 3,
            "title": "Action Required",
            "actionType": "approve",
            "actionURL": "myapp://approve/123",
            "expiresAt": "2026-02-07T10:30:00Z",
            "timestamp": "2026-01-31T12:00:00Z",
            "isRead": true
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        let dto = try JSONDecoder().decode(NotificationDTO.self, from: data)
        
        guard case let .action(actionNotification) = dto else {
            Issue.record("Expected action notification but got different type")
            return
        }
        
        #expect(actionNotification.id == "notif_789")
        #expect(actionNotification.type == 3)
        #expect(actionNotification.title == "Action Required")
        #expect(actionNotification.actionType == "approve")
        #expect(actionNotification.actionURL == "myapp://approve/123")
        #expect(actionNotification.expiresAt == "2026-02-07T10:30:00Z")
        #expect(actionNotification.isRead == true)
    }
    
    @Test("잘못된 type 값으로 디코딩 실패")
    func testDecodeInvalidType() throws {
        let json = """
        {
            "id": "notif_invalid",
            "type": 999,
            "title": "Invalid",
            "content": "This should fail"
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(NotificationDTO.self, from: data)
        }
    }
    
    // MARK: - Encoding Tests
    
    @Test("TextNotification 인코딩")
    func testEncodeTextNotification() throws {
        let textNotification = TextNotificationDTO(
            id: "notif_001",
            type: 1,
            title: "Test",
            content: "Test content",
            timestamp: "2026-01-31T10:00:00Z",
            isRead: false
        )
        
        let dto = NotificationDTO.text(textNotification)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        
        let data = try encoder.encode(dto)
        let json = try #require(String(data: data, encoding: .utf8))
        
        #expect(json.contains("\"id\":\"notif_001\""))
        #expect(json.contains("\"type\":1"))
        #expect(json.contains("\"title\":\"Test\""))
        #expect(json.contains("\"content\":\"Test content\""))
    }
    
    @Test("ImageNotification 인코딩")
    func testEncodeImageNotification() throws {
        let imageNotification = ImageNotificationDTO(
            id: "notif_002",
            type: 2,
            title: "Image Test",
            imageURL: "https://example.com/image.jpg",
            thumbnail: "https://example.com/thumb.jpg",
            timestamp: "2026-01-31T11:00:00Z",
            isRead: true
        )
        
        let dto = NotificationDTO.image(imageNotification)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        
        let data = try encoder.encode(dto)
        let json = try #require(String(data: data, encoding: .utf8))
        
        // JSON 필드 존재 여부 확인 (이스케이프 무시)
        #expect(json.contains("\"id\":\"notif_002\""))
        #expect(json.contains("\"type\":2"))
        #expect(json.contains("\"imageURL\""))
        #expect(json.contains("example.com/image.jpg"))
        #expect(json.contains("\"thumbnail\""))
        #expect(json.contains("example.com/thumb.jpg"))
    }
    
    // MARK: - Round-trip Tests
    
    @Test("Union 타입 인코딩/디코딩 왕복 테스트")
    func testRoundTrip() throws {
        let original = NotificationDTO.action(
            ActionNotificationDTO(
                id: "notif_round",
                type: 3,
                title: "Round Trip",
                actionType: "test",
                actionURL: "myapp://test",
                expiresAt: "2026-02-01T00:00:00Z",
                timestamp: "2026-01-31T15:00:00Z",
                isRead: false
            )
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationDTO.self, from: encoded)
        
        #expect(decoded == original)
    }
}

// MARK: - TextNotificationDTO Tests

@Suite("TextNotificationDTO Tests")
struct TextNotificationDTOTests {
    
    @Test("TextNotificationDTO mock 데이터 생성")
    func testMock() throws {
        let dto = TextNotificationDTO.mock()
        
        #expect(!dto.id.isEmpty)
        #expect(dto.type == 1)
        #expect(!dto.title.isEmpty)
        #expect(!dto.content.isEmpty)
        
        dto.assertValid()
    }
    
    @Test("TextNotificationDTO mock이 매번 다른 값을 생성")
    func testMockRandomness() throws {
        let dto1 = TextNotificationDTO.mock()
        let dto2 = TextNotificationDTO.mock()
        
        #expect(dto1.id != dto2.id || dto1.title != dto2.title)
    }
    
    @Test("TextNotificationDTO builder로 고정 시나리오 생성")
    func testBuilder() throws {
        let dto = TextNotificationDTO.builder()
            .with(id: "notif_custom_001")
            .with(type: 1)
            .with(title: "Custom Title")
            .with(content: "Custom content message")
            .with(timestamp: "2026-01-31T10:00:00Z")
            .with(isRead: false)
            .build()
        
        #expect(dto.id == "notif_custom_001")
        #expect(dto.type == 1)
        #expect(dto.title == "Custom Title")
        #expect(dto.content == "Custom content message")
        #expect(dto.isRead == false)
        
        dto.assertValid()
    }
    
    @Test("TextNotificationDTO builder로 일부만 커스터마이징")
    func testBuilderPartial() throws {
        let dto = TextNotificationDTO.builder()
            .with(title: "Partial Title")
            .with(isRead: true)
            .build()
        
        #expect(dto.title == "Partial Title")
        #expect(dto.isRead == true)
        #expect(!dto.id.isEmpty)
        #expect(!dto.content.isEmpty)
    }
    
    @Test("TextNotificationDTO mockArray 생성")
    func testMockArray() throws {
        let dtos = TextNotificationDTO.mockArray(count: 3)
        
        #expect(dtos.count == 3)
        for dto in dtos {
            #expect(!dto.id.isEmpty)
            #expect(dto.type == 1)
            dto.assertValid()
        }
    }
}

// MARK: - ImageNotificationDTO Tests

@Suite("ImageNotificationDTO Tests")
struct ImageNotificationDTOTests {
    
    @Test("ImageNotificationDTO mock 데이터 생성")
    func testMock() throws {
        let dto = ImageNotificationDTO.mock()
        
        #expect(!dto.id.isEmpty)
        #expect(dto.type == 2)
        #expect(!dto.title.isEmpty)
        #expect(!dto.imageURL.isEmpty)
        #expect(!dto.thumbnail.isEmpty)
        
        dto.assertValid()
    }
    
    @Test("ImageNotificationDTO builder로 고정 시나리오 생성")
    func testBuilder() throws {
        let dto = ImageNotificationDTO.builder()
            .with(id: "notif_img_custom")
            .with(type: 2)
            .with(title: "High Resolution Photo")
            .with(imageURL: "https://picsum.photos/1920/1080")
            .with(thumbnail: "https://picsum.photos/400/300")
            .with(timestamp: "2026-01-31T11:30:00Z")
            .with(isRead: false)
            .build()
        
        #expect(dto.id == "notif_img_custom")
        #expect(dto.imageURL == "https://picsum.photos/1920/1080")
        #expect(dto.thumbnail == "https://picsum.photos/400/300")
        
        dto.assertValid()
    }
    
    @Test("ImageNotificationDTO mockArray 생성")
    func testMockArray() throws {
        let dtos = ImageNotificationDTO.mockArray(count: 5)
        
        #expect(dtos.count == 5)
        for dto in dtos {
            #expect(dto.type == 2)
            #expect(!dto.imageURL.isEmpty)
            dto.assertValid()
        }
    }
}

// MARK: - ActionNotificationDTO Tests

@Suite("ActionNotificationDTO Tests")
struct ActionNotificationDTOTests {
    
    @Test("ActionNotificationDTO mock 데이터 생성")
    func testMock() throws {
        let dto = ActionNotificationDTO.mock()
        
        #expect(!dto.id.isEmpty)
        #expect(dto.type == 3)
        #expect(!dto.title.isEmpty)
        #expect(!dto.actionType.isEmpty)
        #expect(!dto.actionURL.isEmpty)
        
        dto.assertValid()
    }
    
    @Test("ActionNotificationDTO builder로 고정 시나리오 생성 - 승인 요청")
    func testBuilderApprove() throws {
        let dto = ActionNotificationDTO.builder()
            .with(id: "notif_action_approve")
            .with(type: 3)
            .with(title: "Approve Request")
            .with(actionType: "approve")
            .with(actionURL: "myapp://approve/request_123")
            .with(expiresAt: "2026-02-07T23:59:59Z")
            .with(timestamp: "2026-01-31T13:00:00Z")
            .with(isRead: false)
            .build()
        
        #expect(dto.actionType == "approve")
        #expect(dto.actionURL == "myapp://approve/request_123")
        #expect(dto.isRead == false)
        
        dto.assertValid()
    }
    
    @Test("ActionNotificationDTO builder로 고정 시나리오 생성 - 결제 확인")
    func testBuilderConfirm() throws {
        let dto = ActionNotificationDTO.builder()
            .with(id: "notif_action_payment")
            .with(type: 3)
            .with(title: "Confirm Payment")
            .with(actionType: "confirm")
            .with(actionURL: "myapp://payment/confirm/789")
            .with(expiresAt: "2026-02-01T23:59:59Z")
            .with(timestamp: "2026-01-31T14:00:00Z")
            .with(isRead: true)
            .build()
        
        #expect(dto.actionType == "confirm")
        #expect(dto.actionURL.contains("payment"))
        #expect(dto.isRead == true)
        
        dto.assertValid()
    }
    
    @Test("ActionNotificationDTO mockArray 생성")
    func testMockArray() throws {
        let dtos = ActionNotificationDTO.mockArray(count: 3)
        
        #expect(dtos.count == 3)
        for dto in dtos {
            #expect(dto.type == 3)
            #expect(!dto.actionType.isEmpty)
            dto.assertValid()
        }
    }
}
