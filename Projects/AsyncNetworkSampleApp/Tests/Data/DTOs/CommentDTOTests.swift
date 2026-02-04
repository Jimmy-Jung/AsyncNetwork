//
//  CommentDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/12.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("CommentDTO Tests")
struct CommentDTOTests {
    // MARK: - Mock Tests

    @Test("CommentDTO.random()이 올바른 데이터를 생성하는지 확인")
    func commentDTOMock() throws {
        // When
        let mock = CommentDTO.random()

        // Then
        #expect(mock.id > 0)
        #expect(mock.postId > 0)
        #expect(!mock.name.isEmpty)
        #expect(!mock.email.isEmpty)
        #expect(!mock.body.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("CommentDTO.random()이 매번 다른 값을 생성하는지 확인")
    func commentDTOMockRandomness() {
        // When
        let mock1 = CommentDTO.random()
        let mock2 = CommentDTO.random()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.name != mock2.name)
    }

    @Test("CommentDTO.randomArray()가 여러 개의 Mock을 생성하는지 확인")
    func commentDTOMockArray() throws {
        // When
        let mocks = CommentDTO.randomArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("CommentDTO.randomArray()가 기본 개수로 생성하는지 확인")
    func commentDTOMockArrayDefaultCount() {
        // When ()
        let mocks = CommentDTO.randomArray()

        // Then
        #expect(mocks.count == 10)
    }

    // MARK: - Fixture Tests

    @Test("CommentDTO.fixture()가 일관된 데이터를 생성하는지 확인")
    func commentDTOFixture() {
        // When
        let fixture1 = CommentDTO.fixture()
            .with(id: 1)
            .with(postId: 1)
            .with(name: "id labore ex et quam laborum")
            .with(email: "eliseo@example.com")
            .with(body: "Test body")
            .build()
        let fixture2 = CommentDTO.fixture()
            .with(id: 1)
            .with(postId: 1)
            .with(name: "id labore ex et quam laborum")
            .with(email: "eliseo@example.com")
            .with(body: "Test body")
            .build()

        // Then - Fixture는 항상 동일한 값
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.postId == fixture2.postId)
        #expect(fixture1.name == fixture2.name)
        #expect(fixture1.email == fixture2.email)
        #expect(fixture1.body == fixture2.body)

        // 고정 값 확인
        #expect(fixture1.id == 1)
        #expect(fixture1.postId == 1)
        #expect(fixture1.name == "id labore ex et quam laborum")
        #expect(fixture1.email == "eliseo@example.com")
    }

    // MARK: - Builder Tests

    @Test("CommentDTO.fixture()가 커스텀 데이터를 생성하는지 확인")
    func commentDTOBuilder() throws {
        // Given
        let customName = "Custom Commenter"
        let customEmail = "test@example.com"
        let customBody = "Custom comment body"

        // When
        let custom = CommentDTO.fixture()
            .with(id: 999)
            .with(postId: 42)
            .with(name: customName)
            .with(email: customEmail)
            .with(body: customBody)
            .build()

        // Then
        #expect(custom.id == 999)
        #expect(custom.postId == 42)
        #expect(custom.name == customName)
        #expect(custom.email == customEmail)
        #expect(custom.body == customBody)

        custom.assertValid()
    }

    @Test("CommentDTO.fixture()가 일부만 커스터마이징하는지 확인 (하이브리드 패턴)")
    func commentDTOBuilderPartial() throws {
        // When - email만 변경, 나머지는 mock 기반 랜덤
        let partial = CommentDTO.fixture()
            .with(email: "newemail@test.com")
            .build()

        // Then
        #expect(partial.email == "newemail@test.com") // 고정
        #expect(partial.id > 0) // 랜덤
        #expect(partial.postId > 0) // 랜덤
        #expect(!partial.name.isEmpty) // 랜덤
        #expect(!partial.body.isEmpty) // 랜덤

        partial.assertValid()
    }

    // MARK: - Builder + Mock 실전 예시

    @Test("실전 예시: 특정 postId를 가진 댓글들 생성")
    func builderRealWorldExample1() {
        // Given - Post ID 100에 대한 댓글 5개 생성
        let postId = 100
        let comments = (1 ... 5).map { index in
            CommentDTO.fixture()
                .with(id: index)
                .with(postId: postId)
                // name, email, body는 랜덤
                .build()
        }

        // Then
        #expect(comments.count == 5)

        for comment in comments {
            #expect(comment.postId == postId) // 모두 같은 postId
            #expect(!comment.name.isEmpty) // 랜덤 값
            #expect(!comment.email.isEmpty) // 랜덤 값
            comment.assertValid()
        }
    }

    @Test("실전 예시: 테스트용 관리자 댓글 vs 일반 댓글")
    func builderRealWorldExample2() {
        // Given - 관리자 댓글 (고정 email)
        let adminComment = CommentDTO.fixture()
            .with(email: "admin@example.com")
            .with(name: "Administrator")
            // id, postId, body는 랜덤
            .build()

        // Given - 일반 사용자 댓글 (완전 랜덤)
        let userComment = CommentDTO.random()

        // Then
        #expect(adminComment.email == "admin@example.com")
        #expect(adminComment.name == "Administrator")
        #expect(!userComment.email.isEmpty)

        adminComment.assertValid()
        userComment.assertValid()
    }

    // MARK: - JSON Sample Tests (제거됨 - v1.3.1에서 jsonSample 제거)

    @Test("CommentDTO를 JSON으로 인코딩/디코딩할 수 있는지 확인")
    func commentDTOJsonSample() throws {
        // Given - Builder로 샘플 데이터 생성
        let sample = CommentDTO.fixture()
            .with(id: 1)
            .with(postId: 1)
            .with(name: "Test Comment")
            .with(email: "test@example.com")
            .with(body: "Test body")
            .build()

        // When - JSON으로 인코딩
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(sample)

        // Then - 디코딩 가능한지 확인
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CommentDTO.self, from: jsonData)

        #expect(decoded.id > 0)
        #expect(!decoded.name.isEmpty)
        #expect(!decoded.email.isEmpty)
    }

    // MARK: - Codable Tests

    @Test("CommentDTO가 Codable을 준수하는지 확인")
    func commentDTOCodable() throws {
        // Given
        let original = CommentDTO.random()

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CommentDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.postId == original.postId)
        #expect(decoded.name == original.name)
        #expect(decoded.email == original.email)
        #expect(decoded.body == original.body)
    }

    // MARK: - Domain Model Conversion Tests

    @Test("CommentDTO가 Comment 도메인 모델로 올바르게 변환되는지 확인")
    func commentDTOToDomainModel() {
        // Given
        let dto = CommentDTO.fixture()
            .with(id: 1)
            .with(postId: 1)
            .with(name: "Test Comment")
            .with(email: "test@example.com")
            .with(body: "Test body")
            .build()

        // When
        let domainModel = Comment(dto: dto)

        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.postId == dto.postId)
        #expect(domainModel.name == dto.name)
        #expect(domainModel.email == dto.email)
        #expect(domainModel.body == dto.body)
    }

    @Test("Comment 도메인 모델이 CommentDTO로 올바르게 변환되는지 확인")
    func commentToDTO() {
        // Given
        let comment = Comment(
            id: 1,
            postId: 10,
            name: "Test Commenter",
            email: "test@example.com",
            body: "Test comment body"
        )

        // When
        let dto = CommentDTO(comment: comment)

        // Then
        #expect(dto.id == comment.id)
        #expect(dto.postId == comment.postId)
        #expect(dto.name == comment.name)
        #expect(dto.email == comment.email)
        #expect(dto.body == comment.body)
    }

    @Test("Mock CommentDTO를 도메인 모델로 변환 후 다시 DTO로 변환해도 동일한지 확인")
    func roundTripConversion() {
        // Given
        let originalDTO = CommentDTO.fixture()
            .with(id: 1)
            .with(postId: 1)
            .with(name: "Test Comment")
            .with(email: "test@example.com")
            .with(body: "Test body")
            .build()

        // When
        let domain = Comment(dto: originalDTO)
        let convertedDTO = CommentDTO(comment: domain)

        // Then
        #expect(convertedDTO.id == originalDTO.id)
        #expect(convertedDTO.postId == originalDTO.postId)
        #expect(convertedDTO.name == originalDTO.name)
        #expect(convertedDTO.email == originalDTO.email)
        #expect(convertedDTO.body == originalDTO.body)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func invalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "id": 1,
          "name": "Test Comment"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(CommentDTO.self, from: data)
        }
    }

    @Test("타입이 맞지 않는 JSON으로 디코딩 실패하는지 확인")
    func invalidTypeJSON() {
        // Given - id가 문자열인 경우
        let invalidJSON = """
        {
          "postId": 1,
          "id": "not_a_number",
          "name": "Test",
          "email": "test@example.com",
          "body": "Test body"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(CommentDTO.self, from: data)
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
            try decoder.decode(CommentDTO.self, from: data)
        }
    }

    @Test("잘못된 JSON 형식으로 디코딩 실패하는지 확인")
    func testMalformedJSON() {
        // Given - 유효하지 않은 JSON
        let malformedJSON = """
        {
          "postId": 1,
          "id": 1
          "name": "missing comma"
        }
        """
        let data = malformedJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(CommentDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func nullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "postId": null,
          "id": 1,
          "name": "Test",
          "email": "test@example.com",
          "body": "Test body"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(CommentDTO.self, from: data)
        }
    }
}
