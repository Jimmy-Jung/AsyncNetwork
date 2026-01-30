//
//  ResponseTestableMacroValidationTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/30.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

@Suite("@ResponseTestable Macro JSON Validation Tests")
struct ResponseTestableMacroValidationTests {
    // MARK: - Missing Required Fields

    @Test("fixtureJSON에 필수 필드가 누락되면 경고를 발생시킨다")
    func missingRequiredFields() {
        let source = """
        @ResponseTestable(
            fixtureJSON: \"\"\"
            {
                "id": 1
            }
            \"\"\"
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
            let email: String
        }
        """

        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String
                let email: String

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> UserDTO {
                    UserDTO(
                        id: Int.random(in: 1...1000),
                        name: "Name-\\(UUID().uuidString.prefix(8))",
                        email: "Email-\\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> UserDTO {
                    let json = "{\\n    \\"id\\": 1\\n}"
                    do {
                        return try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
                    } catch {
                        fatalError("[ResponseTestable] Invalid fixtureJSON for UserDTO: \\(error)")
                    }
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 3) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension UserDTO: TestableDTO {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "fixtureJSON validation failed: fixtureJSON is missing required fields: name, email. Please check that the JSON structure matches the struct definition and all nested types have valid fixture data.",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - Extra Fields

    @Test("fixtureJSON에 불필요한 필드가 있으면 경고를 발생시킨다")
    func extraFields() {
        let source = """
        @ResponseTestable(
            fixtureJSON: \"\"\"
            {
                "id": 1,
                "name": "Test",
                "unknownField": "value"
            }
            \"\"\"
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
        }
        """

        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> UserDTO {
                    UserDTO(
                        id: Int.random(in: 1...1000),
                        name: "Name-\\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> UserDTO {
                    let json = "{\\n    \\"id\\": 1,\\n    \\"name\\": \\"Test\\",\\n    \\"unknownField\\": \\"value\\"\\n}"
                    do {
                        return try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
                    } catch {
                        fatalError("[ResponseTestable] Invalid fixtureJSON for UserDTO: \\(error)")
                    }
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 3) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension UserDTO: TestableDTO {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "fixtureJSON validation failed: fixtureJSON contains extra fields not in struct: unknownField. Please check that the JSON structure matches the struct definition and all nested types have valid fixture data.",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - Type Mismatch

    @Test("fixtureJSON의 타입이 struct 정의와 다르면 경고를 발생시킨다")
    func typeMismatch() {
        let source = """
        @ResponseTestable(
            fixtureJSON: \"\"\"
            {
                "id": "not-a-number",
                "name": "Test"
            }
            \"\"\"
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
        }
        """

        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> UserDTO {
                    UserDTO(
                        id: Int.random(in: 1...1000),
                        name: "Name-\\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> UserDTO {
                    let json = "{\\n    \\"id\\": \\"not-a-number\\",\\n    \\"name\\": \\"Test\\"\\n}"
                    do {
                        return try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
                    } catch {
                        fatalError("[ResponseTestable] Invalid fixtureJSON for UserDTO: \\(error)")
                    }
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 3) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension UserDTO: TestableDTO {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "fixtureJSON validation failed: Field 'id' type mismatch: expected Number but got String. Please check that the JSON structure matches the struct definition and all nested types have valid fixture data.",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - Valid JSON

    @Test("fixtureJSON이 올바르면 경고를 발생시키지 않는다")
    func validJSON() {
        let source = """
        @ResponseTestable(
            fixtureJSON: \"\"\"
            {
                "id": 1,
                "name": "Test",
                "email": "test@example.com"
            }
            \"\"\"
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
            let email: String
        }
        """

        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String
                let email: String

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> UserDTO {
                    UserDTO(
                        id: Int.random(in: 1...1000),
                        name: "Name-\\(UUID().uuidString.prefix(8))",
                        email: "Email-\\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> UserDTO {
                    let json = "{\\n    \\"id\\": 1,\\n    \\"name\\": \\"Test\\",\\n    \\"email\\": \\"test@example.com\\"\\n}"
                    do {
                        return try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
                    } catch {
                        fatalError("[ResponseTestable] Invalid fixtureJSON for UserDTO: \\(error)")
                    }
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 3) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension UserDTO: TestableDTO {
            }
            """,
            diagnostics: [], // 경고 없음
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }

    // MARK: - Optional Fields

    @Test("Optional 필드는 fixtureJSON에 없어도 경고를 발생시키지 않는다")
    func optionalFieldsAllowed() {
        let source = """
        @ResponseTestable(
            fixtureJSON: \"\"\"
            {
                "id": 1,
                "name": "Test"
            }
            \"\"\"
        )
        struct UserDTO: Codable, Sendable {
            let id: Int
            let name: String
            let email: String?
        }
        """

        assertMacroExpansion(
            source,
            expandedSource: """
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String
                let email: String?

                /// 랜덤 값으로 테스트 데이터 생성
                ///
                /// 매번 다른 랜덤 값을 생성합니다. (Int.random, UUID().uuidString 등)
                /// - 테스트 시 고정값이 필요하면 fixture() 또는 builder()를 사용하세요
                /// - fixture(): 고정된 값 (fixtureJSON 또는 기본값)
                /// - builder(): fixture() 기반으로 일부만 커스터마이징
                public static func mock() -> UserDTO {
                    UserDTO(
                        id: Int.random(in: 1...1000),
                        name: "Name-\\(UUID().uuidString.prefix(8))",
                        email: "Email-\\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 고정 값으로 테스트 데이터 생성
                public static func fixture() -> UserDTO {
                    let json = "{\\n    \\"id\\": 1,\\n    \\"name\\": \\"Test\\"\\n}"
                    do {
                        return try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
                    } catch {
                        fatalError("[ResponseTestable] Invalid fixtureJSON for UserDTO: \\(error)")
                    }
                }

                /// 여러 개의 Mock 데이터 생성
                public static func mockArray(count: Int = 3) -> [Self] {
                    (0..<count).map { _ in mock() }
                }

                /// 데이터 검증
                public func assertValid() {
                    // No validation rules
                }
            }

            extension UserDTO: TestableDTO {
            }
            """,
            diagnostics: [], // 경고 없음 (email은 optional이므로)
            macros: [
                "ResponseTestable": ResponseTestableMacroImpl.self
            ]
        )
    }
}
