//
//  TestableDTOMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/06.
//

@_exported import AsyncNetworkCore

/// Codable DTO의 테스트 데이터 생성 및 검증 로직을 자동 생성하는 매크로
///
/// **⚠️ Deprecated**: 이 매크로는 `@Response`로 명칭이 변경되었습니다.
/// `@Response` 매크로를 사용하세요.
///
/// ## 마이그레이션 가이드
///
/// **이전 코드:**
/// ```swift
/// @TestableDTO(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "Test User"
///     }
///     """
/// )
/// struct User: Codable { }
/// ```
///
/// **새 코드:**
/// ```swift
/// @Response(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "Test User"
///     }
///     """
/// )
/// struct User: Codable { }
/// ```
///
/// 이 매크로를 사용하면 다음 메서드들이 자동으로 생성됩니다:
/// - `static func mock() -> Self`: 랜덤 값으로 테스트 데이터 생성
/// - `static func fixture() -> Self`: 고정 값으로 테스트 데이터 생성
/// - `static func builder() -> [TypeName]Builder`: Builder 패턴으로 유연한 데이터 생성
/// - `static func mockArray(count: Int) -> [Self]`: 여러 개의 Mock 데이터 생성
/// - `static var jsonSample: String`: JSON 샘플 문자열
/// - `func assertValid() throws`: 데이터 검증
///
/// ## 기본 사용법
///
/// ```swift
/// @TestableDTO(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "Test User",
///       "email": "test@example.com"
///     }
///     """
/// )
/// struct User: Codable {
///     let id: Int
///     let name: String
///     let email: String
/// }
/// ```
///
/// ## OpenAPI 연동
///
/// `fixtureJSON`에 정의된 값은 OpenAPI 스펙 생성 시 자동으로 `example`로 사용됩니다:
///
/// ```swift
/// @TestableDTO(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "Test User",
///       "email": "test@example.com",
///       "age": 25,
///       "isActive": true
///     }
///     """
/// )
/// struct User: Codable {
///     let id: Int
///     let name: String
///     let email: String
///     let age: Int?
///     let isActive: Bool
/// }
/// ```
///
/// 위 코드는 다음과 같은 OpenAPI 스펙을 생성합니다:
///
/// ```json
/// {
///   "components": {
///     "schemas": {
///       "User": {
///         "type": "object",
///         "properties": { ... },
///         "example": {
///           "id": 1,
///           "name": "Test User",
///           "email": "test@example.com",
///           "age": 25,
///           "isActive": true
///         }
///       }
///     }
///   }
/// }
/// ```
///
/// ## 생성되는 메서드 사용 예시
///
/// ```swift
/// // Mock 데이터 (랜덤값)
/// let user1 = User.mock()
/// let user2 = User.mock()  // 다른 값
///
/// // Fixture (고정값)
/// let fixture = User.fixture()  // 항상 동일한 값
///
/// // Builder 패턴
/// let custom = User.builder()
///     .with(name: "Custom Name")
///     .with(age: 30)
///     .build()
///
/// // 배열 생성
/// let users = User.mockArray(count: 10)
///
/// // JSON 샘플
/// let json = User.jsonSample
///
/// // 검증
/// try user1.assertValid()
/// ```
///
/// ## Swift Testing과 함께 사용
///
/// ```swift
/// import Testing
/// @testable import YourModule
///
/// @Test("User 생성 및 검증")
/// func testUserCreation() throws {
///     let user = User.mock()
///     try user.assertValid()
///     #expect(user.id > 0)
///     #expect(!user.name.isEmpty)
/// }
///
/// @Test("User fixture 일관성")
/// func testUserFixture() {
///     let fixture1 = User.fixture()
///     let fixture2 = User.fixture()
///     #expect(fixture1.id == fixture2.id)
///     #expect(fixture1.name == fixture2.name)
/// }
/// ```
///
/// ## 옵션
///
/// - `mockStrategy`: Mock 생성 전략 (기본값: `.random`)
/// - `fixtureJSON`: OpenAPI 및 Fixture에 사용될 JSON 문자열
/// - `includeBuilder`: Builder 패턴 생성 여부 (기본값: `true`)
/// - `defaultArrayCount`: `mockArray()` 기본 개수 (기본값: `5`)
///
/// ## 주의사항
///
/// - 이 매크로는 `Codable` 프로토콜을 준수하는 `struct`에만 적용할 수 있습니다.
/// - `fixtureJSON`은 유효한 JSON 형식이어야 합니다.
/// - 생성된 코드는 컴파일 타임에 확장되므로 런타임 오버헤드가 없습니다.
@available(*, deprecated, renamed: "Response", message: "Use @Response instead")
@attached(member, names:
    named(mock),
    named(fixture),
    named(builder),
    named(mockArray),
    named(jsonSample),
    named(assertValid),
    arbitrary // Builder 타입 (예: UserBuilder)
)
@attached(extension, conformances: TestableDTO)
public macro TestableDTO(
    /// Mock 생성 전략
    mockStrategy: MockStrategy = .random,

    /// OpenAPI 및 Fixture에 사용될 JSON 문자열
    /// ExportOpenAPI.swift가 이 값을 파싱하여 OpenAPI 스펙의 example로 사용합니다
    fixtureJSON: String? = nil,

    /// Builder 패턴 생성 여부
    includeBuilder: Bool = true,

    /// mockArray() 메서드의 기본 개수
    defaultArrayCount: Int = 5
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "TestableDTOMacroImpl"
)

/// Mock 생성 전략
public enum MockStrategy {
    /// 랜덤 값 생성
    case random
    /// 고정 값 생성 (fixtureJSON 기반)
    case fixture
    /// 순차적으로 증가하는 값 생성
    case sequential
}

/// TestableDTO 프로토콜
/// @TestableDTO 매크로를 적용한 타입이 자동으로 채택합니다
public protocol TestableDTO {
    /// 랜덤 값으로 테스트 데이터 생성
    static func mock() -> Self

    /// 고정 값으로 테스트 데이터 생성
    static func fixture() -> Self

    /// 여러 개의 Mock 데이터 생성
    static func mockArray(count: Int) -> [Self]

    /// JSON 샘플 문자열
    static var jsonSample: String { get }

    /// 데이터 검증
    func assertValid() throws
}
