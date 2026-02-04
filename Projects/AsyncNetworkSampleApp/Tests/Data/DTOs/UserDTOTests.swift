//
//  UserDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/12.
//

@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("UserDTO Tests")
struct UserDTOTests {
    // MARK: - Mock Tests

    @Test("UserDTO.random()이 올바른 데이터를 생성하는지 확인")
    func userDTOMock() throws {
        // When
        let mock = UserDTO.random()

        // Then
        #expect(mock.id > 0)
        #expect(!mock.name.isEmpty)
        #expect(!mock.username.isEmpty)
        #expect(!mock.email.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("UserDTO.random()이 매번 다른 값을 생성하는지 확인")
    func userDTOMockRandomness() {
        // When
        let mock1 = UserDTO.random()
        let mock2 = UserDTO.random()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.name != mock2.name)
    }

    @Test("UserDTO.randomArray()가 여러 개의 Mock을 생성하는지 확인")
    func userDTOMockArray() throws {
        // When
        let mocks = UserDTO.randomArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("UserDTO.randomArray()가 기본 개수로 생성하는지 확인")
    func userDTOMockArrayDefaultCount() {
        // When ()
        let mocks = UserDTO.randomArray()

        // Then
        #expect(mocks.count == 10)
    }

    // MARK: - Builder Tests

    @Test("UserDTO.fixture()가 커스텀 데이터를 생성하는지 확인")
    func userDTOBuilder() throws {
        // Given
        let customName = "Custom User"
        let customEmail = "custom@example.com"

        // When
        let custom = UserDTO.fixture()
            .with(id: 999)
            .with(name: customName)
            .with(username: "customuser")
            .with(email: customEmail)
            .with(phone: "123-456-7890")
            .with(website: "example.com")
            .build()

        // Then
        #expect(custom.id == 999)
        #expect(custom.name == customName)
        #expect(custom.username == "customuser")
        #expect(custom.email == customEmail)
        #expect(custom.phone == "123-456-7890")
        #expect(custom.website == "example.com")

        custom.assertValid()
    }

    @Test("UserDTO.fixture()가 일부만 커스터마이징하는지 확인")
    func userDTOBuilderPartial() throws {
        // When - name만 변경, 나머지는 랜덤
        let partial = UserDTO.fixture()
            .with(name: "Partial User")
            .build()

        // Then
        #expect(partial.name == "Partial User")
        #expect(partial.id > 0)
        #expect(!partial.username.isEmpty)
        #expect(!partial.email.isEmpty)

        partial.assertValid()
    }

    @Test("UserDTO.fixture()로 고정 시나리오 테스트")
    func userDTOBuilderFixedScenario() throws {
        // Given - 특정 테스트 시나리오: 관리자 계정
        let adminUser = UserDTO.fixture()
            .with(id: 1)
            .with(name: "Admin User")
            .with(username: "admin")
            .with(email: "admin@example.com")
            .with(phone: "555-0000")
            .with(website: "admin.example.com")
            .with(address: nil)
            .with(company: nil)
            .build()

        // Then
        #expect(adminUser.id == 1)
        #expect(adminUser.name == "Admin User")
        #expect(adminUser.username == "admin")
        #expect(adminUser.email == "admin@example.com")
        #expect(adminUser.address == nil)
        #expect(adminUser.company == nil)

        adminUser.assertValid()
    }

    // MARK: - Codable Tests

    @Test("UserDTO가 Codable을 준수하는지 확인")
    func userDTOCodable() throws {
        // Given
        let original = UserDTO.random()

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.username == original.username)
        #expect(decoded.email == original.email)
    }

    // MARK: - Domain Model Conversion Tests

    @Test("UserDTO가 User 도메인 모델로 올바르게 변환되는지 확인")
    func userDTOToDomainModel() {
        // Given - Builder로 고정 값 생성
        let dto = UserDTO.fixture()
            .with(id: 1)
            .with(name: "Leanne Graham")
            .with(username: "Bret")
            .with(email: "Sincere@april.biz")
            .with(phone: "1-770-736-8031 x56442")
            .with(website: "hildegard.org")
            .build()

        // When
        let domainModel = User(dto: dto)

        // Then
        #expect(domainModel.id == dto.id)
        #expect(domainModel.name == dto.name)
        #expect(domainModel.username == dto.username)
        #expect(domainModel.email == dto.email)
        #expect(domainModel.phone == dto.phone)
        #expect(domainModel.website == dto.website)
    }

    @Test("UserDTO의 옵셔널 필드가 nil일 때 도메인 모델로 올바르게 변환되는지 확인")
    func userDTOWithNilOptionalsToDomainModel() {
        // Given
        let dto = UserDTO.fixture()
            .with(id: 1)
            .with(name: "Test User")
            .with(username: "testuser")
            .with(email: "test@example.com")
            .with(address: nil)
            .with(phone: nil)
            .with(website: nil)
            .with(company: nil)
            .build()

        // When
        let domainModel = User(dto: dto)

        // Then
        #expect(domainModel.address == nil)
        #expect(domainModel.phone == nil)
        #expect(domainModel.website == nil)
        #expect(domainModel.company == nil)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func invalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "id": 1,
          "name": "Test User"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(UserDTO.self, from: data)
        }
    }

    @Test("타입이 맞지 않는 JSON으로 디코딩 실패하는지 확인")
    func invalidTypeJSON() {
        // Given - id가 문자열인 경우
        let invalidJSON = """
        {
          "id": "not_a_number",
          "name": "Test",
          "username": "test",
          "email": "test@example.com"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(UserDTO.self, from: data)
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
            try decoder.decode(UserDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func nullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "id": 1,
          "name": null,
          "username": "test",
          "email": "test@example.com"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(UserDTO.self, from: data)
        }
    }

    @Test("중첩된 객체의 타입이 맞지 않을 때 디코딩 실패하는지 확인")
    func invalidNestedObjectType() {
        // Given - address.geo가 문자열인 경우
        let invalidJSON = """
        {
          "id": 1,
          "name": "Test User",
          "username": "test",
          "email": "test@example.com",
          "address": {
            "street": "Test St",
            "suite": "Apt 1",
            "city": "Test City",
            "zipcode": "12345",
            "geo": "invalid_geo_object"
          }
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(UserDTO.self, from: data)
        }
    }
}

@Suite("AddressDTO Tests")
struct AddressDTOTests {
    // MARK: - Mock Tests

    @Test("AddressDTO.random()이 올바른 데이터를 생성하는지 확인")
    func addressDTOMock() throws {
        // When
        let mock = AddressDTO.random()

        // Then
        #expect(!mock.street.isEmpty)
        #expect(!mock.suite.isEmpty)
        #expect(!mock.city.isEmpty)
        #expect(!mock.zipcode.isEmpty)

        mock.assertValid()
    }

    // MARK: - Builder Tests

    @Test("AddressDTO.fixture()로 고정 값 생성")
    func addressDTOBuilder() {
        // When - Builder로 고정 시나리오 생성
        let address = AddressDTO.fixture()
            .with(street: "Kulas Light")
            .with(suite: "Apt. 556")
            .with(city: "Gwenborough")
            .with(zipcode: "92998-3874")
            .build()

        // Then
        #expect(address.street == "Kulas Light")
        #expect(address.suite == "Apt. 556")
        #expect(address.city == "Gwenborough")
        #expect(address.zipcode == "92998-3874")
    }

    // MARK: - Domain Model Conversion Tests

    @Test("AddressDTO가 Address 도메인 모델로 올바르게 변환되는지 확인")
    func addressDTOToDomainModel() {
        // Given - Builder로 고정 값 생성
        let dto = AddressDTO.fixture()
            .with(street: "Test Street")
            .with(suite: "Suite 100")
            .with(city: "Test City")
            .with(zipcode: "12345")
            .build()

        // When
        let domainModel = Address(dto: dto)

        // Then
        #expect(domainModel.street == dto.street)
        #expect(domainModel.suite == dto.suite)
        #expect(domainModel.city == dto.city)
        #expect(domainModel.zipcode == dto.zipcode)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func testInvalidJSONStructure() {
        // Given - 필수 필드 누락 (geo 누락)
        let invalidJSON = """
        {
          "street": "Test St",
          "suite": "Apt 1",
          "city": "Test City",
          "zipcode": "12345"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(AddressDTO.self, from: data)
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
            try decoder.decode(AddressDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func testNullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "street": null,
          "suite": "Apt 1",
          "city": "Test City",
          "zipcode": "12345",
          "geo": {
            "lat": "-37.3159",
            "lng": "81.1496"
          }
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(AddressDTO.self, from: data)
        }
    }
}

@Suite("GeoDTO Tests")
struct GeoDTOTests {
    // MARK: - Mock Tests

    @Test("GeoDTO.random()이 올바른 데이터를 생성하는지 확인")
    func geoDTOMock() throws {
        // When
        let mock = GeoDTO.random()

        // Then
        #expect(!mock.lat.isEmpty)
        #expect(!mock.lng.isEmpty)

        mock.assertValid()
    }

    // MARK: - Builder Tests

    @Test("GeoDTO.fixture()로 고정 값 생성")
    func geoDTOBuilder() {
        // When - Builder로 고정 좌표 생성
        let geo = GeoDTO.fixture()
            .with(lat: "-37.3159")
            .with(lng: "81.1496")
            .build()

        // Then
        #expect(geo.lat == "-37.3159")
        #expect(geo.lng == "81.1496")
    }

    // MARK: - Domain Model Conversion Tests

    @Test("GeoDTO가 Geo 도메인 모델로 올바르게 변환되는지 확인")
    func geoDTOToDomainModel() {
        // Given - Builder로 고정 값 생성
        let dto = GeoDTO.fixture()
            .with(lat: "-37.3159")
            .with(lng: "81.1496")
            .build()

        // When
        let domainModel = Geo(dto: dto)

        // Then
        #expect(domainModel.lat == dto.lat)
        #expect(domainModel.lng == dto.lng)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func testInvalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "lat": "-37.3159"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GeoDTO.self, from: data)
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
            try decoder.decode(GeoDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func testNullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "lat": null,
          "lng": "81.1496"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(GeoDTO.self, from: data)
        }
    }
}

@Suite("CompanyDTO Tests")
struct CompanyDTOTests {
    // MARK: - Mock Tests

    @Test("CompanyDTO.random()이 올바른 데이터를 생성하는지 확인")
    func companyDTOMock() throws {
        // When
        let mock = CompanyDTO.random()

        // Then
        #expect(!mock.name.isEmpty)
        #expect(!mock.catchPhrase.isEmpty)
        #expect(!mock.bs.isEmpty)

        mock.assertValid()
    }

    // MARK: - Builder Tests

    @Test("CompanyDTO.fixture()로 고정 값 생성")
    func companyDTOBuilder() {
        // When - Builder로 특정 회사 정보 생성
        let company = CompanyDTO.fixture()
            .with(name: "Romaguera-Crona")
            .with(catchPhrase: "Multi-layered client-server neural-net")
            .with(bs: "harness real-time e-markets")
            .build()

        // Then
        #expect(company.name == "Romaguera-Crona")
        #expect(company.catchPhrase == "Multi-layered client-server neural-net")
        #expect(company.bs == "harness real-time e-markets")
    }

    // MARK: - Domain Model Conversion Tests

    @Test("CompanyDTO가 Company 도메인 모델로 올바르게 변환되는지 확인")
    func companyDTOToDomainModel() {
        // Given - Builder로 고정 값 생성
        let dto = CompanyDTO.fixture()
            .with(name: "Test Company")
            .with(catchPhrase: "Test Phrase")
            .with(bs: "Test BS")
            .build()

        // When
        let domainModel = Company(dto: dto)

        // Then
        #expect(domainModel.name == dto.name)
        #expect(domainModel.catchPhrase == dto.catchPhrase)
        #expect(domainModel.bs == dto.bs)
    }

    // MARK: - Error Response Tests

    @Test("잘못된 JSON 구조로 디코딩 실패하는지 확인")
    func testInvalidJSONStructure() {
        // Given - 필수 필드 누락
        let invalidJSON = """
        {
          "name": "Test Company"
        }
        """
        let data = invalidJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(CompanyDTO.self, from: data)
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
            try decoder.decode(CompanyDTO.self, from: data)
        }
    }

    @Test("null 값이 필수 필드에 있을 때 디코딩 실패하는지 확인")
    func testNullRequiredFields() {
        // Given
        let nullJSON = """
        {
          "name": "Test Company",
          "catchPhrase": null,
          "bs": "Test bs"
        }
        """
        let data = nullJSON.data(using: .utf8)!

        // When & Then
        let decoder = JSONDecoder()
        #expect(throws: Error.self) {
            try decoder.decode(CompanyDTO.self, from: data)
        }
    }
}
