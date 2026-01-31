//
//  AlbumDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/12.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("AlbumDTO Tests")
struct AlbumDTOTests {
    // MARK: - Mock Tests

    @Test("AlbumDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func albumDTOMock() throws {
        // When
        let mock = AlbumDTO.mock()

        // Then
        #expect(mock.id > 0)
        #expect(mock.userId > 0)
        #expect(!mock.title.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("AlbumDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func albumDTOMockRandomness() {
        // When
        let mock1 = AlbumDTO.mock()
        let mock2 = AlbumDTO.mock()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }

    @Test("AlbumDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func albumDTOMockArray() throws {
        // When
        let mocks = AlbumDTO.mockArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("AlbumDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func albumDTOMockArrayDefaultCount() {
        // When (defaultArrayCount: 10)
        let mocks = AlbumDTO.mockArray()

        // Then
        #expect(mocks.count == 10)
    }

    // MARK: - Builder Tests (Fixture Replacement)

    @Test("AlbumDTO.builder()가 일관된 데이터를 생성하는지 확인")
    func albumDTOFixture() {
        // When
        let fixture1 = AlbumDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "quidem molestiae enim")
            .build()
        let fixture2 = AlbumDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "quidem molestiae enim")
            .build()

        // Then - Builder로 생성한 값은 항상 동일
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.userId == fixture2.userId)
        #expect(fixture1.title == fixture2.title)

        // 고정 값과 일치
        #expect(fixture1.id == 1)
        #expect(fixture1.userId == 1)
        #expect(fixture1.title == "quidem molestiae enim")
    }

    // MARK: - Builder Tests

    @Test("AlbumDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func albumDTOBuilder() throws {
        // Given
        let customTitle = "Custom Album Title"

        // When
        let custom = AlbumDTO.builder()
            .with(id: 999)
            .with(userId: 42)
            .with(title: customTitle)
            .build()

        // Then
        #expect(custom.id == 999)
        #expect(custom.userId == 42)
        #expect(custom.title == customTitle)

        custom.assertValid()
    }

    @Test("AlbumDTO.builder()가 일부만 커스터마이징하는지 확인")
    func albumDTOBuilderPartial() throws {
        // When - title만 변경
        let partial = AlbumDTO.builder()
            .with(title: "Only Title Changed")
            .build()

        // Then
        #expect(partial.title == "Only Title Changed")
        #expect(partial.id > 0)
        #expect(partial.userId > 0)

        // Note: partial builder는 랜덤 값을 생성하므로
        // 필요한 필드만 검증하고 assertValid()는 생략
    }

    // MARK: - Builder JSON Tests

    @Test("AlbumDTO.builder()로 생성한 데이터가 JSON 인코딩/디코딩되는지 확인")
    func albumDTOJsonSample() throws {
        // Given - Builder로 샘플 데이터 생성
        let sample = AlbumDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "quidem molestiae enim")
            .build()

        // When - Encode
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(sample)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AlbumDTO.self, from: jsonData)

        #expect(decoded.id == 1)
        #expect(decoded.userId == 1)
        #expect(decoded.title == "quidem molestiae enim")
    }

    // MARK: - Codable Tests

    @Test("AlbumDTO가 Codable을 준수하는지 확인")
    func albumDTOCodable() throws {
        // Given
        let original = AlbumDTO.mock()

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AlbumDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.userId == original.userId)
        #expect(decoded.title == original.title)
    }

    // MARK: - Domain Model Conversion Tests

    @Test("AlbumDTO가 Album 도메인 모델로 올바르게 변환되는지 확인")
    func albumDTOToDomainModel() {
        // Given
        let dto = AlbumDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "quidem molestiae enim")
            .build()

        // When
        let domainModel = Album(dto: dto)

        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.userId == dto.userId)
        #expect(domainModel.title == dto.title)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func invalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "id": 1,
          "title": "Test Album"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(AlbumDTO.self, from: data)
        }
    }

    @Test("타입이 맞지 않는 JSON으로 디코딩 실패하는지 확인")
    func invalidTypeJSON() {
        // Given - id가 문자열인 경우
        let invalidJSON = """
        {
          "userId": 1,
          "id": "not_a_number",
          "title": "Test"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(AlbumDTO.self, from: data)
        }
    }

    @Test("빈 JSON 객체로 디코딩 실패하는지 확인")
    func testEmptyJSON() {
        // Given
        let emptyJSON = "{}"
        let data = emptyJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(AlbumDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func nullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "userId": null,
          "id": 1,
          "title": "Test"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(AlbumDTO.self, from: data)
        }
    }
}

@Suite("PhotoDTO Tests")
struct PhotoDTOTests {
    // MARK: - Mock Tests

    @Test("PhotoDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func photoDTOMock() throws {
        // When
        let mock = PhotoDTO.mock()

        // Then
        #expect(mock.id > 0)
        #expect(mock.albumId > 0)
        #expect(!mock.title.isEmpty)
        #expect(!mock.url.isEmpty)
        #expect(!mock.thumbnailUrl.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("PhotoDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func photoDTOMockRandomness() {
        // When
        let mock1 = PhotoDTO.mock()
        let mock2 = PhotoDTO.mock()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }

    @Test("PhotoDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func photoDTOMockArray() throws {
        // When
        let mocks = PhotoDTO.mockArray(count: 50)

        // Then
        #expect(mocks.count == 50)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("PhotoDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func photoDTOMockArrayDefaultCount() {
        // When (defaultArrayCount: 50)
        let mocks = PhotoDTO.mockArray()

        // Then
        #expect(mocks.count == 50)
    }

    // MARK: - Builder Tests (Fixture Replacement)

    @Test("PhotoDTO.builder()가 일관된 데이터를 생성하는지 확인")
    func photoDTOFixture() {
        // When
        let fixture1 = PhotoDTO.builder()
            .with(id: 1)
            .with(albumId: 1)
            .with(title: "accusamus beatae ad facilis cum similique qui sunt")
            .build()
        let fixture2 = PhotoDTO.builder()
            .with(id: 1)
            .with(albumId: 1)
            .with(title: "accusamus beatae ad facilis cum similique qui sunt")
            .build()

        // Then - Builder로 생성한 값은 항상 동일
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.albumId == fixture2.albumId)
        #expect(fixture1.title == fixture2.title)
        #expect(fixture1.url == fixture2.url)
        #expect(fixture1.thumbnailUrl == fixture2.thumbnailUrl)

        // 고정 값과 일치
        #expect(fixture1.id == 1)
        #expect(fixture1.albumId == 1)
        #expect(fixture1.title == "accusamus beatae ad facilis cum similique qui sunt")
    }

    // MARK: - Builder Tests

    @Test("PhotoDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func photoDTOBuilder() throws {
        // Given
        let customTitle = "Custom Photo Title"
        let customUrl = "https://example.com/photo.jpg"
        let customThumbnail = "https://example.com/thumb.jpg"

        // When
        let custom = PhotoDTO.builder()
            .with(id: 999)
            .with(albumId: 42)
            .with(title: customTitle)
            .with(url: customUrl)
            .with(thumbnailUrl: customThumbnail)
            .build()

        // Then
        #expect(custom.id == 999)
        #expect(custom.albumId == 42)
        #expect(custom.title == customTitle)
        #expect(custom.url == customUrl)
        #expect(custom.thumbnailUrl == customThumbnail)

        custom.assertValid()
    }

    // MARK: - Codable Tests

    @Test("PhotoDTO가 Codable을 준수하는지 확인")
    func photoDTOCodable() throws {
        // Given
        let original = PhotoDTO.mock()

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PhotoDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.albumId == original.albumId)
        #expect(decoded.title == original.title)
        #expect(decoded.url == original.url)
        #expect(decoded.thumbnailUrl == original.thumbnailUrl)
    }

    // MARK: - Domain Model Conversion Tests

    @Test("PhotoDTO가 Photo 도메인 모델로 올바르게 변환되는지 확인")
    func photoDTOToDomainModel() {
        // Given
        let dto = PhotoDTO.builder()
            .with(id: 1)
            .with(albumId: 1)
            .with(title: "accusamus beatae ad facilis cum similique qui sunt")
            .build()

        // When
        let domainModel = Photo(dto: dto)

        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.albumId == dto.albumId)
        #expect(domainModel.title == dto.title)
        #expect(domainModel.url == dto.url)
        #expect(domainModel.thumbnailUrl == dto.thumbnailUrl)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func testInvalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "id": 1,
          "title": "Test Photo"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PhotoDTO.self, from: data)
        }
    }

    @Test("타입이 맞지 않는 JSON으로 디코딩 실패하는지 확인")
    func testInvalidTypeJSON() {
        // Given - albumId가 문자열인 경우
        let invalidJSON = """
        {
          "id": 1,
          "albumId": "not_a_number",
          "title": "Test",
          "url": "https://example.com/photo.jpg",
          "thumbnailUrl": "https://example.com/thumb.jpg"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PhotoDTO.self, from: data)
        }
    }

    @Test("빈 JSON 객체로 디코딩 실패하는지 확인")
    func testEmptyJSON() {
        // Given
        let emptyJSON = "{}"
        let data = emptyJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PhotoDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func testNullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "id": 1,
          "albumId": 1,
          "title": null,
          "url": "https://example.com/photo.jpg",
          "thumbnailUrl": "https://example.com/thumb.jpg"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PhotoDTO.self, from: data)
        }
    }
}
