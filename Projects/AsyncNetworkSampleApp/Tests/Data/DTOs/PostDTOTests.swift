//
//  PostDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("PostDTO Tests")
struct PostDTOTests {
    // MARK: - Mock Tests

    @Test("PostDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func postDTOMock() throws {
        // When
        let mock = PostDTO.mock()

        // Then
        #expect(mock.id > 0)
        #expect(mock.userId > 0)
        #expect(!mock.title.isEmpty)
        #expect(!mock.body.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("PostDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func postDTOMockRandomness() {
        // When
        let mock1 = PostDTO.mock()
        let mock2 = PostDTO.mock()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }

    @Test("PostDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func postDTOMockArray() throws {
        // When
        let mocks = PostDTO.mockArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("PostDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func postDTOMockArrayDefaultCount() {
        // When (defaultArrayCount: 10)
        let mocks = PostDTO.mockArray()

        // Then
        #expect(mocks.count == 10)
    }

    // MARK: - Builder Tests (Fixture Replacement)

    @Test("PostDTO.builder()가 일관된 데이터를 생성하는지 확인")
    func postDTOBuilderFixture() {
        // When
        let fixture1 = PostDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
            .with(body: "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            .build()
        
        let fixture2 = PostDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
            .with(body: "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            .build()

        // Then - Builder로 생성한 값은 항상 동일
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.userId == fixture2.userId)
        #expect(fixture1.title == fixture2.title)
        #expect(fixture1.body == fixture2.body)

        // 고정 값 검증
        #expect(fixture1.id == 1)
        #expect(fixture1.userId == 1)
        #expect(fixture1.title.contains("sunt aut facere"))
    }

    // MARK: - Builder Tests

    @Test("PostDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func postDTOBuilder() throws {
        // Given
        let customTitle = "Custom Test Title"
        let customBody = "Custom Test Body"

        // When
        let custom = PostDTO.builder()
            .with(id: 999)
            .with(userId: 42)
            .with(title: customTitle)
            .with(body: customBody)
            .build()

        // Then
        #expect(custom.id == 999)
        #expect(custom.userId == 42)
        #expect(custom.title == customTitle)
        #expect(custom.body == customBody)

        custom.assertValid()
    }

    @Test("PostDTO.builder()가 일부만 커스터마이징하는지 확인")
    func postDTOBuilderPartial() throws {
        // When - title만 변경
        let partial = PostDTO.builder()
            .with(title: "Only Title Changed")
            .build()

        // Then
        #expect(partial.title == "Only Title Changed")
        #expect(partial.id > 0) // 나머지는 자동 생성
        #expect(partial.userId > 0)
        #expect(!partial.body.isEmpty)

        partial.assertValid()
    }

    // MARK: - JSON Sample Tests (Builder-based)

    @Test("PostDTO.builder()로 생성한 샘플이 유효한 JSON으로 인코딩/디코딩되는지 확인")
    func postDTOBuilderJsonSample() throws {
        // Given - Builder로 샘플 생성
        let sample = PostDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
            .with(body: "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            .build()

        // When - Encode
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(sample)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostDTO.self, from: jsonData)

        #expect(decoded.id == sample.id)
        #expect(decoded.userId == sample.userId)
        #expect(decoded.title == sample.title)
        #expect(decoded.body == sample.body)
        #expect(decoded.id > 0)
        #expect(!decoded.title.isEmpty)
    }

    // MARK: - Codable Tests

    @Test("PostDTO가 Codable을 준수하는지 확인")
    func postDTOCodable() throws {
        // Given
        let original = PostDTO.mock()

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.userId == original.userId)
        #expect(decoded.title == original.title)
        #expect(decoded.body == original.body)
    }

    // MARK: - Domain Model Conversion Tests

    @Test("PostDTO가 Post 도메인 모델로 올바르게 변환되는지 확인")
    func postDTOToDomainModel() {
        // Given
        let dto = PostDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
            .with(body: "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            .build()

        // When
        let domainModel = Post(dto: dto)

        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.userId == dto.userId)
        #expect(domainModel.title == dto.title)
        #expect(domainModel.body == dto.body)
    }

    @Test("Post 도메인 모델이 PostDTO로 올바르게 변환되는지 확인")
    func postToDTO() {
        // Given
        let post = Post(
            id: 1,
            userId: 10,
            title: "Test Post",
            body: "Test Body"
        )

        // When
        let dto = PostDTO(post: post)

        // Then
        #expect(dto.id == post.id)
        #expect(dto.userId == post.userId)
        #expect(dto.title == post.title)
        #expect(dto.body == post.body)
    }

    @Test("Mock PostDTO를 도메인 모델로 변환 후 다시 DTO로 변환해도 동일한지 확인")
    func roundTripConversion() {
        // Given
        let originalDTO = PostDTO.builder()
            .with(id: 1)
            .with(userId: 1)
            .with(title: "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
            .with(body: "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            .build()

        // When
        let domain = Post(dto: originalDTO)
        let convertedDTO = PostDTO(post: domain)

        // Then
        #expect(convertedDTO.id == originalDTO.id)
        #expect(convertedDTO.userId == originalDTO.userId)
        #expect(convertedDTO.title == originalDTO.title)
        #expect(convertedDTO.body == originalDTO.body)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func invalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "id": 1,
          "title": "Test Post"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PostDTO.self, from: data)
        }
    }

    @Test("타입이 맞지 않는 JSON으로 디코딩 실패하는지 확인")
    func invalidTypeJSON() {
        // Given - userId가 문자열인 경우
        let invalidJSON = """
        {
          "userId": "not_a_number",
          "id": 1,
          "title": "Test",
          "body": "Test body"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PostDTO.self, from: data)
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
            try decoder.decode(PostDTO.self, from: data)
        }
    }

    @Test("잘못된 JSON 형식으로 디코딩 실패하는지 확인")
    func testMalformedJSON() {
        // Given - 유효하지 않은 JSON
        let malformedJSON = """
        {
          "userId": 1,
          "id": 1
          "title": "missing comma"
        }
        """
        let data = malformedJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PostDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func nullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "userId": 1,
          "id": null,
          "title": "Test",
          "body": "Test body"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(PostDTO.self, from: data)
        }
    }
}
