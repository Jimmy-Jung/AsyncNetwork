//
//  PostDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/06.
//

import Foundation
import Testing
@testable import AsyncNetworkSampleApp

@Suite("PostDTO Tests")
struct PostDTOTests {
    
    // MARK: - Mock Tests
    
    @Test("PostDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func testPostDTOMock() throws {
        // When
        let mock = PostDTO.mock()
        
        // Then
        #expect(mock.id > 0)
        #expect(mock.userId > 0)
        #expect(!mock.title.isEmpty)
        #expect(!mock.body.isEmpty)
        
        // 검증
        try mock.assertValid()
    }
    
    @Test("PostDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func testPostDTOMockRandomness() {
        // When
        let mock1 = PostDTO.mock()
        let mock2 = PostDTO.mock()
        
        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }
    
    @Test("PostDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func testPostDTOMockArray() throws {
        // When
        let mocks = PostDTO.mockArray(count: 10)
        
        // Then
        #expect(mocks.count == 10)
        
        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            try mock.assertValid()
        }
    }
    
    @Test("PostDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func testPostDTOMockArrayDefaultCount() {
        // When (defaultArrayCount: 10)
        let mocks = PostDTO.mockArray()
        
        // Then
        #expect(mocks.count == 10)
    }
    
    // MARK: - Fixture Tests
    
    @Test("PostDTO.fixture()가 일관된 데이터를 반환하는지 확인")
    func testPostDTOFixture() {
        // When
        let fixture1 = PostDTO.fixture()
        let fixture2 = PostDTO.fixture()
        
        // Then - Fixture는 항상 동일한 값
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.userId == fixture2.userId)
        #expect(fixture1.title == fixture2.title)
        #expect(fixture1.body == fixture2.body)
        
        // fixtureJSON에 정의된 값과 일치
        #expect(fixture1.id == 1)
        #expect(fixture1.userId == 1)
        #expect(fixture1.title.contains("sunt aut facere"))
    }
    
    // MARK: - Builder Tests
    
    @Test("PostDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func testPostDTOBuilder() throws {
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
        
        try custom.assertValid()
    }
    
    @Test("PostDTO.builder()가 일부만 커스터마이징하는지 확인")
    func testPostDTOBuilderPartial() throws {
        // When - title만 변경
        let partial = PostDTO.builder()
            .with(title: "Only Title Changed")
            .build()
        
        // Then
        #expect(partial.title == "Only Title Changed")
        #expect(partial.id > 0)  // 나머지는 자동 생성
        #expect(partial.userId > 0)
        #expect(!partial.body.isEmpty)
        
        try partial.assertValid()
    }
    
    // MARK: - JSON Sample Tests
    
    @Test("PostDTO.jsonSample이 유효한 JSON인지 확인")
    func testPostDTOJsonSample() throws {
        // When
        let jsonString = PostDTO.jsonSample
        let jsonData = jsonString.data(using: .utf8)!
        
        // Then
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostDTO.self, from: jsonData)
        
        #expect(decoded.id > 0)
        #expect(!decoded.title.isEmpty)
    }
    
    // MARK: - Codable Tests
    
    @Test("PostDTO가 Codable을 준수하는지 확인")
    func testPostDTOCodable() throws {
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
    func testPostDTOToDomainModel() {
        // Given
        let dto = PostDTO.fixture()
        
        // When
        let domainModel = Post(dto: dto)
        
        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.userId == dto.userId)
        #expect(domainModel.title == dto.title)
        #expect(domainModel.body == dto.body)
    }
    
    @Test("Post 도메인 모델이 PostDTO로 올바르게 변환되는지 확인")
    func testPostToDTO() {
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
    func testRoundTripConversion() {
        // Given
        let originalDTO = PostDTO.fixture()
        
        // When
        let domain = Post(dto: originalDTO)
        let convertedDTO = PostDTO(post: domain)
        
        // Then
        #expect(convertedDTO.id == originalDTO.id)
        #expect(convertedDTO.userId == originalDTO.userId)
        #expect(convertedDTO.title == originalDTO.title)
        #expect(convertedDTO.body == originalDTO.body)
    }
}


