//
//  ResponseTestableMacroTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

@Suite("@ResponseTestable Macro Tests")
struct ResponseTestableMacroTests {
    // MARK: - 배열 타입 Mock 생성 테스트

    @Test("@ResponseTestable이 배열 프로퍼티에 대해 Mock 데이터를 생성하는지 확인")
    func arrayPropertyMockGeneration() {
        // Given
        let source = """
        @ResponseTestable(defaultArrayCount: 5)
        struct ResponseWithArray: Codable, Sendable {
            let items: [ItemDTO]
        }
        """

        // When & Then - items가 랜덤 개수의 Mock을 생성하는지 확인
        assertMacroExpansion(
            source,
            expandedSource: """
            struct ResponseWithArray: Codable, Sendable {
                let items: [ItemDTO]

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> ResponseWithArray {
                    ResponseWithArray(
                        items: (0..<Int.random(in: 2...5)).map { _ in ItemDTO.mock() }
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> ResponseWithArray {
                    ResponseWithArray(
                        items: []
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension ResponseWithArray: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - 다양한 타입 테스트

    @Test("@ResponseTestable이 모든 기본 타입을 올바르게 생성하는지 확인")
    func allBasicTypes() {
        // Given
        let source = """
        @ResponseTestable()
        struct AllTypesDTO: Codable, Sendable {
            let int: Int
            let int8: Int8
            let int16: Int16
            let int32: Int32
            let int64: Int64
            let uint: UInt
            let uint8: UInt8
            let string: String
            let bool: Bool
            let double: Double
            let float: Float
            let cgfloat: CGFloat
            let date: Date
            let uuid: UUID
            let url: URL
            let decimal: Decimal
            let data: Data
        }
        """

        // When & Then - 각 타입이 올바른 Mock 값을 생성하는지 확인
        assertMacroExpansion(
            source,
            expandedSource: """
            struct AllTypesDTO: Codable, Sendable {
                let int: Int
                let int8: Int8
                let int16: Int16
                let int32: Int32
                let int64: Int64
                let uint: UInt
                let uint8: UInt8
                let string: String
                let bool: Bool
                let double: Double
                let float: Float
                let cgfloat: CGFloat
                let date: Date
                let uuid: UUID
                let url: URL
                let decimal: Decimal
                let data: Data

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> AllTypesDTO {
                    AllTypesDTO(
                        int: Int.random(in: 1...1000),
                        int8: Int8.random(in: 1...127),
                        int16: Int16.random(in: 1...1000),
                        int32: Int32.random(in: 1...1000),
                        int64: Int64.random(in: 1...1000),
                        uint: UInt.random(in: 1...1000),
                        uint8: UInt8.random(in: 1...255),
                        string: "Mock \\(UUID().uuidString.prefix(8))",
                        bool: Bool.random(),
                        double: Double.random(in: 0...100),
                        float: Float.random(in: 0...100),
                        cgfloat: CGFloat.random(in: 0...100),
                        date: Date(),
                        uuid: UUID(),
                        url: URL(string: "https://example.com")!,
                        decimal: Decimal(Double.random(in: 0...100)),
                        data: Data()
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> AllTypesDTO {
                    AllTypesDTO(
                        int: 1,
                        int8: 1,
                        int16: 1,
                        int32: 1,
                        int64: 1,
                        uint: 1,
                        uint8: 1,
                        string: "Test String",
                        bool: true,
                        double: 0.0,
                        float: 0.0,
                        cgfloat: CGFloat(0.0),
                        date: Date(timeIntervalSince1970: 1704556800),
                        uuid: UUID(),
                        url: URL(string: "https://example.com")!,
                        decimal: Decimal(0),
                        data: Data()
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension AllTypesDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - Optional 타입 테스트

    @Test("@ResponseTestable이 Optional 프로퍼티를 올바르게 처리하는지 확인")
    func optionalProperties() {
        // Given
        let source = """
        @ResponseTestable()
        struct OptionalDTO: Codable, Sendable {
            let required: String
            let optional: String?
            let optionalId: Int?
        }
        """

        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct OptionalDTO: Codable, Sendable {
                let required: String
                let optional: String?
                let optionalId: Int?

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> OptionalDTO {
                    OptionalDTO(
                        required: "Mock \\(UUID().uuidString.prefix(8))",
                        optional: Bool.random() ? "Mock \\(UUID().uuidString.prefix(8))" : nil,
                        optionalId: Bool.random() ? Int.random(in: 1...1000) : nil
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> OptionalDTO {
                    OptionalDTO(
                        required: "Test String",
                        optional: nil,
                        optionalId: nil
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    assert(!required.isEmpty, "required must not be empty")
                    if let optionalId = optionalId {
                        assert(optionalId > 0, "optionalId must be positive")
                    }
                }
            }

            extension OptionalDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - 특수 필드명 테스트

    @Test("@ResponseTestable이 email 필드를 올바르게 생성하는지 확인")
    func emailFieldGeneration() {
        // Given
        let source = """
        @ResponseTestable()
        struct UserDTO: Codable, Sendable {
            let email: String
            let userEmail: String?
        }
        """

        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let email: String
                let userEmail: String?

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> UserDTO {
                    UserDTO(
                        email: "mock\\(Int.random(in: 1...999))@example.com",
                        userEmail: Bool.random() ? "mock\\(Int.random(in: 1...999))@example.com" : nil
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> UserDTO {
                    UserDTO(
                        email: "Test String",
                        userEmail: nil
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    assert(email.contains("@") && email.contains("."), "email must be valid email")
                    assert(!email.starts(with: "@") && !email.starts(with: "."), "email format invalid")
                    if let userEmail = userEmail {
                        assert(userEmail.contains("@") && userEmail.contains("."), "userEmail must be valid email")
                        assert(!userEmail.starts(with: "@") && !userEmail.starts(with: "."), "userEmail format invalid")
                    }
                }
            }

            extension UserDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - 딕셔너리 및 Set 타입 테스트

    @Test("@ResponseTestable이 Dictionary와 Set을 올바르게 생성하는지 확인")
    func dictionaryAndSetTypes() {
        // Given
        let source = """
        @ResponseTestable()
        struct CollectionDTO: Codable, Sendable {
            let dict: [String: Int]
            let set: Set<String>
        }
        """

        // When & Then
        assertMacroExpansion(
            source,
            expandedSource: """
            struct CollectionDTO: Codable, Sendable {
                let dict: [String: Int]
                let set: Set<String>

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> CollectionDTO {
                    CollectionDTO(
                        dict: [:],
                        set: Set((0..<Int.random(in: 2...5)).map { _ in String.mock() })
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> CollectionDTO {
                    CollectionDTO(
                        dict: [:],
                        set: Set()
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension CollectionDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - Builder 패턴 테스트

    @Test("@ResponseTestable이 Builder를 올바르게 생성하는지 확인")
    func builderGeneration() {
        // Given
        let source = """
        @ResponseTestable(defaultArrayCount: 5)
        struct BuilderDTO: Codable, Sendable {
            let id: Int
            let name: String
        }
        """

        // When & Then - Builder가 Sendable을 채택하는지 확인
        assertMacroExpansion(
            source,
            expandedSource: """
            struct BuilderDTO: Codable, Sendable {
                let id: Int
                let name: String

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> BuilderDTO {
                    BuilderDTO(
                        id: Int.random(in: 1...1000),
                        name: "Mock \\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> BuilderDTO {
                    BuilderDTO(
                        id: 1,
                        name: "Test String"
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    assert(id > 0, "id must be positive")
                    assert(!name.isEmpty, "name must not be empty")
                }

                /// Builder 패턴으로 유연한 데이터 생성
                ///
                /// Builder는 fixture() 값을 기본값으로 사용합니다.
                /// - 주입하지 않은 값은 fixture()의 고정값을 사용 (예측 가능한 테스트)
                /// - 랜덤 값이 필요하면 mock() 메서드를 사용하세요
                ///
                /// Example:
                /// ```swift
                /// let dto = DTO.builder()
                ///     .with(id: 999)
                ///     .with(name: "Custom")
                ///     .build()
                /// // id와 name만 커스텀, 나머지는 fixture() 값 사용
                /// ```
                public static func builder() -> BuilderDTOBuilder {
                    BuilderDTOBuilder()
                }

                /// Builder 패턴
                ///
                /// 모든 프로퍼티는 fixture() 값으로 초기화됩니다.
                /// - fixtureJSON이 있으면 해당 값 사용
                /// - fixtureJSON이 없으면 타입별 기본값 사용 (Int: 1, String: "Test String" 등)
                /// - with() 메서드로 원하는 값만 커스터마이징 가능
                /// - 예측 가능한 고정값으로 안정적인 테스트 작성
                public struct BuilderDTOBuilder: Sendable {
                    private var id: Int = 1
                    private var name: String = "Test String"

                public func with(id: Int) -> Self {
                    var copy = self
                    copy.id = id
                    return copy
                }

                public func with(name: String) -> Self {
                        var copy = self
                        copy.name = name
                        return copy
                    }

                    /// Builder로 설정된 값들로 인스턴스 생성
                    public func build() -> BuilderDTO {
                        BuilderDTO(
                            id: id,
                            name: name
                        )
                    }
                }
            }

            extension BuilderDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - fixtureJSON 에러 처리 테스트

    @Test("@ResponseTestable이 잘못된 fixtureJSON에 대해 명확한 에러를 제공하는지 확인")
    func invalidFixtureJSONErrorHandling() {
        // Given - 의도적으로 잘못된 JSON
        let source = """
        @ResponseTestable(
            fixtureJSON: \"""
            {
              "id": "invalid_not_int",
              "name": "Test"
            }
            \"""
        )
        struct ErrorDTO: Codable, Sendable {
            let id: Int
            let name: String
        }
        """

        // When & Then - do-catch로 명확한 에러 메시지 제공
        assertMacroExpansion(
            source,
            expandedSource: """
            struct ErrorDTO: Codable, Sendable {
                let id: Int
                let name: String

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> ErrorDTO {
                    ErrorDTO(
                        id: Int.random(in: 1...1000),
                        name: "Mock \\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> ErrorDTO {
                    let json = "{\\n  \\"id\\": \\"invalid_not_int\\",\\n  \\"name\\": \\"Test\\"\\n}"
                    do {
                        return try JSONDecoder().decode(ErrorDTO.self, from: Data(json.utf8))
                    } catch {
                        fatalError("[ResponseTestable] Invalid fixtureJSON for ErrorDTO: \\(error)")
                    }
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    assert(id > 0, "id must be positive")
                    assert(!name.isEmpty, "name must not be empty")
                }

                /// JSON 샘플 문자열
                ///
                /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
                /// fixtureJSON과 동일한 내용을 포함합니다.
                public static var jsonSample: String {
                    \"""
                    {
                      "id": "invalid_not_int",
                      "name": "Test"
                    }
                    \"""
                }
            }

            extension ErrorDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - 중첩 DTO 테스트

    @Test("@ResponseTestable이 중첩된 커스텀 타입을 올바르게 처리하는지 확인")
    func nestedCustomTypes() {
        // Given
        let source = """
        @ResponseTestable()
        struct ParentDTO: Codable, Sendable {
            let child: ChildDTO
            let children: [ChildDTO]
        }
        """

        // When & Then - child.mock() 및 배열 ChildDTO.mock() 호출
        assertMacroExpansion(
            source,
            expandedSource: """
            struct ParentDTO: Codable, Sendable {
                let child: ChildDTO
                let children: [ChildDTO]

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> ParentDTO {
                    ParentDTO(
                        child: ChildDTO.mock(),
                        children: (0..<Int.random(in: 2...5)).map { _ in ChildDTO.mock() }
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> ParentDTO {
                    ParentDTO(
                        child: ChildDTO.fixture(),
                        children: []
                    )
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 5) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension ParentDTO: TestableDTO {
            }
            """,
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }
}
