//
//  TestableDTOTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetworkMacros
import Foundation
import Testing

@TestableDTO(
    fixtureJSON: """
    {
      "id": 1,
      "name": "Test User",
      "email": "test@example.com"
    }
    """
)
struct TestUser: Codable {
    let id: Int
    let name: String
    let email: String
}

@Suite("@TestableDTO Macro Tests")
struct TestableDTOTests {
    @Test("Mock 생성 테스트")
    func mockGeneration() throws {
        let user = TestUser.mock()

        #expect(user.id > 0)
        #expect(!user.name.isEmpty)
        #expect(user.email.contains("@"))
    }

    @Test("Fixture 생성 테스트")
    func fixtureGeneration() {
        let fixture1 = TestUser.fixture()
        let fixture2 = TestUser.fixture()

        // Fixture는 항상 동일한 값
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.name == fixture2.name)
        #expect(fixture1.email == fixture2.email)

        // fixtureJSON과 일치
        #expect(fixture1.id == 1)
        #expect(fixture1.name == "Test User")
        #expect(fixture1.email == "test@example.com")
    }

    @Test("Mock 배열 생성 테스트")
    func mockArrayGeneration() {
        let users = TestUser.mockArray(count: 10)

        #expect(users.count == 10)

        // 각 사용자가 고유한 값을 가질 가능성이 높음
        let uniqueIds = Set(users.map { $0.id })
        #expect(uniqueIds.count >= 8) // 최소 80% 유니크
    }

    @Test("JSON 샘플 테스트")
    func jSONSample() throws {
        let json = TestUser.jsonSample

        #expect(json.contains("\"id\""))
        #expect(json.contains("\"name\""))
        #expect(json.contains("\"email\""))

        // JSON 디코딩 가능 여부 확인
        let user = try JSONDecoder().decode(TestUser.self, from: Data(json.utf8))
        #expect(user.id == 1)
    }

    @Test("검증 메서드 테스트")
    func testAssertValid() throws {
        let user = TestUser.fixture()
        try user.assertValid() // 예외 발생하지 않아야 함
    }

    @Test("Builder 패턴 테스트")
    func builderPattern() {
        let user = TestUser.builder()
            .with(id: 100)
            .with(name: "Custom Name")
            .with(email: "custom@test.com")
            .build()

        #expect(user.id == 100)
        #expect(user.name == "Custom Name")
        #expect(user.email == "custom@test.com")
    }
}
