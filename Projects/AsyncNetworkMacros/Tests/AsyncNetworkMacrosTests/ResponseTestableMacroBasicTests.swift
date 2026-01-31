//
//  ResponseTestableMacroBasicTests.swift
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

@Suite("@ResponseTestable Macro Basic Tests")
struct ResponseTestableMacroBasicTests {

    // MARK: - 배열 타입 Mock 생성 테스트

    @Test("@ResponseTestable이 배열 프로퍼티에 대해 Mock 데이터를 생성하는지 확인")
    func testArrayPropertyMockGeneration() {
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
    func testAllBasicTypes() {
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
    func testOptionalProperties() {
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
}
