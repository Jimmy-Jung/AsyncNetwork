//
//  ResponseTestableMacroFixtureTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/29.
//  Split from ResponseTestableMacroSpecialTypesTests.swift - Builder and Fixture tests
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncNetworkMacros
@testable import AsyncNetworkMacrosImpl

@Suite("@ResponseTestable Macro Fixture Tests")
struct ResponseTestableMacroFixtureTests {
    // MARK: - Builder 패턴 테스트

    @Test("@ResponseTestable이 Builder를 올바르게 생성하는지 확인")
    func builderGeneration() {
        // Given
        let source = """
        @ResponseTestable(mockStrategy: .random, includeBuilder: true, defaultArrayCount: 5)
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
                    private var id: Int
                    private var name: String

                    public init() {
                        let fixture = BuilderDTO.fixture()
                        self.id = fixture.id
                        self.name = fixture.name
                    }

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
            \""",
            includeBuilder: false
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
}
