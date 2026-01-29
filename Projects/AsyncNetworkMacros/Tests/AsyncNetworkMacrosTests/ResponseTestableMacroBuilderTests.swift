//
//  ResponseTestableMacroBuilderTests.swift
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

@Suite("@ResponseTestable Macro Builder Tests")
struct ResponseTestableMacroBuilderTests {

    // MARK: - 중첩 DTO 테스트

    @Test("@ResponseTestable이 중첩된 커스텀 타입을 올바르게 처리하는지 확인")
    func testNestedCustomTypes() {
        // Given
        let source = """
        @ResponseTestable(mockStrategy: .random, includeBuilder: false)
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
