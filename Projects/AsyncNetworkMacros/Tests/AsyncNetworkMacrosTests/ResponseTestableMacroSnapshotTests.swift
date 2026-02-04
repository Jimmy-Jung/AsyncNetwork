import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting
#if canImport(AsyncNetworkMacrosImpl)
import AsyncNetworkMacrosImpl
#endif

final class ResponseTestableMacroSnapshotTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: ["ResponseTestable": ResponseTestableMacroImpl.self]
        ) {
            super.invokeTest()
        }
    }

    func testStructWithRandomAndFixture() {
        assertMacro {
            """
            @ResponseTestable(defaultArrayCount: 3)
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String
            }
            """
        } expansion: {
            """
            struct UserDTO: Codable, Sendable {
                let id: Int
                let name: String

                /// 랜덤 값으로 테스트 데이터 생성 (내부 구현)
                public static func random(seed: Int? = nil, depth: Int = 0) -> UserDTO {
                    if depth > 10 {
                    }
                    var generator: RandomNumberGenerator = seed != nil ? SeededRandomNumberGenerator(seed: seed!) : SystemRandomNumberGenerator()
                    return UserDTO(
                        id: Int.random(in: 1...1000, using: &generator),
                        name: "Mock \\(UUID().uuidString.prefix(8))"
                    )
                }

                /// 랜덤 값으로 테스트 데이터 생성 (공개 인터페이스)
                public static func random(seed: Int? = nil) -> UserDTO {
                    random(seed: seed, depth: 0)
                }

                /// 여러 개의 Random 데이터 생성
                public static func randomArray(count: Int = 3, seed: Int? = nil) -> [Self] {
                    var generator: RandomNumberGenerator = seed != nil ? SeededRandomNumberGenerator(seed: seed!) : SystemRandomNumberGenerator()
                    // 시드가 있으면 예측 가능한 난수 시퀀스를 위해 시드를 조금씩 변경하거나, 생성기를 공유해야 함.
                    // 여기서는 단순화를 위해 시드를 증가시키는 방식 사용
                return (0 ..< count).map { i in
                    let itemSeed = seed.map {
                        $0 + i
                    }
                    return random(seed: itemSeed)
                }
                }

                /// 데이터 검증
                public func assertValid() {
                    assert(id > 0, "id must be positive")
                        assert(!name.isEmpty, "name must not be empty")
                }

                /// Builder 패턴으로 유연한 데이터 생성
                ///
                /// Builder는 고정된 fixture 값을 기본값으로 사용합니다.
                /// - 주입하지 않은 값은 일관된 fixture 값을 사용
                /// - 특정 필드만 커스터마이징하고 나머지는 고정 값 사용
                ///
                /// Example:
                /// ```swift
                /// let dto = DTO.fixture()
                ///     .with(id: 999)
                ///     .with(name: "Custom")
                ///     .build()
                /// // id와 name만 고정, 나머지는 fixture 값 사용
                /// ```
                public static func fixture() -> UserDTOFixtureBuilder {
                    UserDTOFixtureBuilder()
                }

                /// 고정 값으로 테스트 데이터 생성 (내부용)
                public static func fixtureValue() -> UserDTO {
                    fixture().build()
                }

                /// Builder 패턴
                ///
                /// 모든 프로퍼티는 고정된 fixture 값으로 초기화됩니다.
                /// - 일관된 고정 값으로 시작하여 원하는 필드만 커스터마이징
                /// - with() 메서드로 원하는 값만 커스터마이징 가능
                /// - 테스트 시나리오별로 특정 필드만 제어할 때 유용
                public struct UserDTOFixtureBuilder: Sendable {
                    private var id: Int
                    private var name: String

                    public init() {
                        self.id = 1
                        self.name = "Test String"
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
                    public func build() -> UserDTO {
                        UserDTO(
                            id: id,
                                name: name
                        )
                    }
                }
            }

            extension UserDTO: TestableDTO {
            }
            """
        }
    }
}
