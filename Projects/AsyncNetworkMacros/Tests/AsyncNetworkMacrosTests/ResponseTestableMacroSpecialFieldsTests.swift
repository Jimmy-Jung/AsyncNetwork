//
//  ResponseTestableMacroSpecialFieldsTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//  Split from ResponseTestableMacroSpecialTypesTests.swift
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

@Suite("@ResponseTestable Macro Special Fields Tests")
struct ResponseTestableMacroSpecialFieldsTests {

    // MARK: - 특수 필드명 테스트

    @Test("@ResponseTestable이 email 필드를 올바르게 생성하는지 확인")
    func testEmailFieldGeneration() {
        // Given
        let source = """
        @ResponseTestable(mockStrategy: .random, includeBuilder: false)
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
    func testDictionaryAndSetTypes() {
        // Given
        let source = """
        @ResponseTestable(mockStrategy: .random, includeBuilder: false)
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

    // MARK: - 딕셔너리 및 Set 타입 테스트

    @Test("@ResponseTestable이 Dictionary와 Set을 올바르게 생성하는지 확인")
    func testDictionaryAndSetTypes() {
        // Given
        let source = """
        @ResponseTestable(mockStrategy: .random, includeBuilder: false)
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
}
