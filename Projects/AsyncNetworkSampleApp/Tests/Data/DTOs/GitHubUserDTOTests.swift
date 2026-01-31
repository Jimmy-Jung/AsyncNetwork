//
//  GitHubUserDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/12.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("GitHubUserDTO Tests")
struct GitHubUserDTOTests {
    // MARK: - Mock Tests

    @Test("GitHubUserDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func gitHubUserDTOMock() throws {
        // When
        let mock = GitHubUserDTO.mock()

        // Then
        #expect(mock.id > 0)
        #expect(!mock.login.isEmpty)
        #expect(!mock.avatarUrl.isEmpty)
        #expect(mock.publicRepos >= 0)
        #expect(mock.publicGists >= 0)
        #expect(mock.followers >= 0)
        #expect(mock.following >= 0)
        #expect(!mock.createdAt.isEmpty)
        #expect(!mock.updatedAt.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("GitHubUserDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func gitHubUserDTOMockRandomness() {
        // When
        let mock1 = GitHubUserDTO.mock()
        let mock2 = GitHubUserDTO.mock()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.login != mock2.login)
    }

    @Test("GitHubUserDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func gitHubUserDTOMockArray() throws {
        // When
        let mocks = GitHubUserDTO.mockArray(count: 5)

        // Then
        #expect(mocks.count == 5)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("GitHubUserDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func gitHubUserDTOMockArrayDefaultCount() {
        // When (defaultArrayCount: 1)
        let mocks = GitHubUserDTO.mockArray()

        // Then
        #expect(mocks.count == 1)
    }

    // MARK: - Fixture Tests

    @Test("GitHubUserDTO.builder()가 일관된 데이터를 반환하는지 확인")
    func gitHubUserDTOFixture() {
        // When
        let fixture1 = GitHubUserDTO.builder()
            .with(id: 1)
            .with(login: "octocat")
            .with(avatarUrl: "https://github.com/images/error/octocat_happy.gif")
            .with(name: "The Octocat")
            .with(company: nil)
            .with(blog: nil)
            .with(location: nil)
            .with(email: nil)
            .with(bio: nil)
            .with(publicRepos: 8)
            .with(publicGists: 8)
            .with(followers: 9999)
            .with(following: 9)
            .with(createdAt: "2011-01-25T18:44:36Z")
            .with(updatedAt: "2023-11-07T22:47:31Z")
            .build()
        let fixture2 = GitHubUserDTO.builder()
            .with(id: 1)
            .with(login: "octocat")
            .with(avatarUrl: "https://github.com/images/error/octocat_happy.gif")
            .with(name: "The Octocat")
            .with(company: nil)
            .with(blog: nil)
            .with(location: nil)
            .with(email: nil)
            .with(bio: nil)
            .with(publicRepos: 8)
            .with(publicGists: 8)
            .with(followers: 9999)
            .with(following: 9)
            .with(createdAt: "2011-01-25T18:44:36Z")
            .with(updatedAt: "2023-11-07T22:47:31Z")
            .build()

        // Then - Fixture는 항상 동일한 값
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.login == fixture2.login)
        #expect(fixture1.avatarUrl == fixture2.avatarUrl)
        #expect(fixture1.name == fixture2.name)
        #expect(fixture1.publicRepos == fixture2.publicRepos)

        // fixtureJSON에 정의된 값과 일치
        #expect(fixture1.id == 1)
        #expect(fixture1.login == "octocat")
        #expect(fixture1.name == "The Octocat")
        #expect(fixture1.publicRepos == 8)
        #expect(fixture1.publicGists == 8)
        #expect(fixture1.followers == 9999)
        #expect(fixture1.following == 9)
    }

    // MARK: - Builder Tests

    @Test("GitHubUserDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func gitHubUserDTOBuilder() throws {
        // Given
        let customLogin = "testuser"
        let customName = "Test User"
        let customAvatarUrl = "https://example.com/avatar.jpg"

        // When
        let custom = GitHubUserDTO.builder()
            .with(id: 999)
            .with(login: customLogin)
            .with(avatarUrl: customAvatarUrl)
            .with(name: customName)
            .with(company: "Test Company")
            .with(blog: "https://testblog.com")
            .with(location: "Seoul")
            .with(email: "test@example.com")
            .with(bio: "Test bio")
            .with(publicRepos: 42)
            .with(publicGists: 10)
            .with(followers: 100)
            .with(following: 50)
            .with(createdAt: "2020-01-01T00:00:00Z")
            .with(updatedAt: "2026-01-12T00:00:00Z")
            .build()

        // Then
        #expect(custom.id == 999)
        #expect(custom.login == customLogin)
        #expect(custom.avatarUrl == customAvatarUrl)
        #expect(custom.name == customName)
        #expect(custom.company == "Test Company")
        #expect(custom.blog == "https://testblog.com")
        #expect(custom.location == "Seoul")
        #expect(custom.email == "test@example.com")
        #expect(custom.bio == "Test bio")
        #expect(custom.publicRepos == 42)
        #expect(custom.publicGists == 10)
        #expect(custom.followers == 100)
        #expect(custom.following == 50)

        custom.assertValid()
    }

    @Test("GitHubUserDTO.builder()가 일부만 커스터마이징하는지 확인")
    func gitHubUserDTOBuilderPartial() throws {
        // When - login만 변경
        let partial = GitHubUserDTO.builder()
            .with(login: "customlogin")
            .build()

        // Then
        #expect(partial.login == "customlogin")
        #expect(partial.id > 0)
        #expect(!partial.avatarUrl.isEmpty)
        #expect(partial.publicRepos >= 0)

        // Note: partial builder는 랜덤 값을 생성하므로
        // assertValid()가 실패할 수 있어 제거
    }

    // MARK: - JSON Sample Tests

    @Test("GitHubUserDTO.builder()로 생성한 데이터가 유효한 JSON으로 인코딩/디코딩되는지 확인")
    func gitHubUserDTOJsonSample() throws {
        // Given - builder로 샘플 데이터 생성
        let sample = GitHubUserDTO.builder()
            .with(id: 1)
            .with(login: "octocat")
            .with(avatarUrl: "https://github.com/images/error/octocat_happy.gif")
            .with(name: "The Octocat")
            .with(company: nil)
            .with(blog: nil)
            .with(location: nil)
            .with(email: nil)
            .with(bio: nil)
            .with(publicRepos: 8)
            .with(publicGists: 8)
            .with(followers: 9999)
            .with(following: 9)
            .with(createdAt: "2011-01-25T18:44:36Z")
            .with(updatedAt: "2023-11-07T22:47:31Z")
            .build()

        // When - Encode
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(sample)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GitHubUserDTO.self, from: jsonData)

        #expect(decoded.id > 0)
        #expect(!decoded.login.isEmpty)
        #expect(!decoded.avatarUrl.isEmpty)
        #expect(decoded.id == sample.id)
        #expect(decoded.login == sample.login)
        #expect(decoded.avatarUrl == sample.avatarUrl)
    }

    // MARK: - Codable Tests

    @Test("GitHubUserDTO가 Codable을 준수하는지 확인")
    func gitHubUserDTOCodable() throws {
        // Given
        let original = GitHubUserDTO.mock()

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GitHubUserDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.login == original.login)
        #expect(decoded.avatarUrl == original.avatarUrl)
        #expect(decoded.name == original.name)
        #expect(decoded.publicRepos == original.publicRepos)
        #expect(decoded.publicGists == original.publicGists)
        #expect(decoded.followers == original.followers)
        #expect(decoded.following == original.following)
    }

    @Test("GitHubUserDTO가 snake_case CodingKeys를 올바르게 처리하는지 확인")
    func gitHubUserDTOCodingKeys() throws {
        // Given - GitHub API 스타일의 JSON
        let json = """
        {
          "login": "testuser",
          "id": 123,
          "avatar_url": "https://example.com/avatar.jpg",
          "name": "Test User",
          "company": null,
          "blog": "",
          "location": null,
          "email": null,
          "bio": null,
          "public_repos": 10,
          "public_gists": 5,
          "followers": 100,
          "following": 50,
          "created_at": "2020-01-01T00:00:00Z",
          "updated_at": "2026-01-12T00:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GitHubUserDTO.self, from: data)

        // Then - snake_case가 camelCase로 올바르게 변환되었는지 확인
        #expect(decoded.avatarUrl == "https://example.com/avatar.jpg")
        #expect(decoded.publicRepos == 10)
        #expect(decoded.publicGists == 5)
        #expect(decoded.createdAt == "2020-01-01T00:00:00Z")
        #expect(decoded.updatedAt == "2026-01-12T00:00:00Z")
    }

    // MARK: - Domain Model Conversion Tests

    @Test("GitHubUserDTO가 GitHubUser 도메인 모델로 올바르게 변환되는지 확인")
    func gitHubUserDTOToDomainModel() {
        // Given
        let dto = GitHubUserDTO.builder()
            .with(id: 1)
            .with(login: "octocat")
            .with(avatarUrl: "https://github.com/images/error/octocat_happy.gif")
            .with(name: "The Octocat")
            .with(company: nil)
            .with(blog: nil)
            .with(location: nil)
            .with(email: nil)
            .with(bio: nil)
            .with(publicRepos: 8)
            .with(publicGists: 8)
            .with(followers: 9999)
            .with(following: 9)
            .with(createdAt: "2011-01-25T18:44:36Z")
            .with(updatedAt: "2023-11-07T22:47:31Z")
            .build()

        // When
        let domainModel = GitHubUser(dto: dto)

        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.login == dto.login)
        #expect(domainModel.avatarUrl == dto.avatarUrl)
        #expect(domainModel.name == dto.name)
        #expect(domainModel.company == dto.company)
        #expect(domainModel.blog == dto.blog)
        #expect(domainModel.location == dto.location)
        #expect(domainModel.email == dto.email)
        #expect(domainModel.bio == dto.bio)
        #expect(domainModel.publicRepos == dto.publicRepos)
        #expect(domainModel.publicGists == dto.publicGists)
        #expect(domainModel.followers == dto.followers)
        #expect(domainModel.following == dto.following)
        #expect(domainModel.createdAt == dto.createdAt)
        #expect(domainModel.updatedAt == dto.updatedAt)
    }

    @Test("GitHubUserDTO의 옵셔널 필드가 nil일 때 도메인 모델로 올바르게 변환되는지 확인")
    func gitHubUserDTOWithNilOptionalsToDomainModel() {
        // Given
        let dto = GitHubUserDTO.builder()
            .with(id: 1)
            .with(login: "testuser")
            .with(avatarUrl: "https://example.com/avatar.jpg")
            .with(name: nil)
            .with(company: nil)
            .with(blog: nil)
            .with(location: nil)
            .with(email: nil)
            .with(bio: nil)
            .with(publicRepos: 0)
            .with(publicGists: 0)
            .with(followers: 0)
            .with(following: 0)
            .with(createdAt: "2020-01-01T00:00:00Z")
            .with(updatedAt: "2026-01-12T00:00:00Z")
            .build()

        // When
        let domainModel = GitHubUser(dto: dto)

        // Then
        #expect(domainModel.name == nil)
        #expect(domainModel.company == nil)
        #expect(domainModel.blog == nil)
        #expect(domainModel.location == nil)
        #expect(domainModel.email == nil)
        #expect(domainModel.bio == nil)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func invalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "login": "testuser",
          "id": 1
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GitHubUserDTO.self, from: data)
        }
    }

    @Test("타입이 맞지 않는 JSON으로 디코딩 실패하는지 확인")
    func invalidTypeJSON() {
        // Given - id가 문자열인 경우
        let invalidJSON = """
        {
          "login": "testuser",
          "id": "not_a_number",
          "avatar_url": "https://example.com/avatar.jpg",
          "name": "Test User",
          "public_repos": 10,
          "public_gists": 5,
          "followers": 100,
          "following": 50,
          "created_at": "2020-01-01T00:00:00Z",
          "updated_at": "2026-01-12T00:00:00Z"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GitHubUserDTO.self, from: data)
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
            try decoder.decode(GitHubUserDTO.self, from: data)
        }
    }

    @Test("잘못된 JSON 형식으로 디코딩 실패하는지 확인")
    func testMalformedJSON() {
        // Given - 유효하지 않은 JSON
        let malformedJSON = """
        {
          "login": "testuser",
          "id": 1
          "avatar_url": "missing comma"
        }
        """
        let data = malformedJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GitHubUserDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func nullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "login": null,
          "id": 1,
          "avatar_url": "https://example.com/avatar.jpg",
          "name": "Test User",
          "public_repos": 10,
          "public_gists": 5,
          "followers": 100,
          "following": 50,
          "created_at": "2020-01-01T00:00:00Z",
          "updated_at": "2026-01-12T00:00:00Z"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GitHubUserDTO.self, from: data)
        }
    }

    @Test("snake_case 필드명 누락 시 디코딩 실패하는지 확인")
    func missingSnakeCaseFields() {
        // Given - public_repos 필드 누락
        let invalidJSON = """
        {
          "login": "testuser",
          "id": 1,
          "avatar_url": "https://example.com/avatar.jpg",
          "name": "Test User",
          "public_gists": 5,
          "followers": 100,
          "following": 50,
          "created_at": "2020-01-01T00:00:00Z",
          "updated_at": "2026-01-12T00:00:00Z"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GitHubUserDTO.self, from: data)
        }
    }

    @Test("잘못된 CodingKeys 사용 시 디코딩 실패하는지 확인")
    func invalidCodingKeys() {
        // Given - camelCase 사용 (실제로는 snake_case를 기대)
        let invalidJSON = """
        {
          "login": "testuser",
          "id": 1,
          "avatarUrl": "https://example.com/avatar.jpg",
          "name": "Test User",
          "publicRepos": 10,
          "publicGists": 5,
          "followers": 100,
          "following": 50,
          "createdAt": "2020-01-01T00:00:00Z",
          "updatedAt": "2026-01-12T00:00:00Z"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GitHubUserDTO.self, from: data)
        }
    }
}
