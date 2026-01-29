//
//  ResponseTestableMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

// MARK: - Deprecated (제거 예정 - v2.0.0)

@available(
    *,
    deprecated,
    message: "MockStrategy is no longer used. Use mock() for random values and fixture() for fixed values."
)
public enum MockStrategy {
    case random
    case fixture
    case sequential
}

// MARK: - TestableDTO 프로토콜

/// 테스트 가능한 DTO 프로토콜
///
/// `@ResponseTestable` 매크로를 적용한 타입이 자동으로 채택합니다.
/// 이 프로토콜을 직접 채택할 필요는 없습니다.
///
/// ## 제공 메서드
///
/// - **mock()**: 랜덤 값으로 테스트 데이터 생성
/// - **fixture()**: 고정 값으로 테스트 데이터 생성
/// - **mockArray(count:)**: 여러 개의 Mock 데이터 생성
/// - **assertValid()**: 데이터 유효성 검증
///
/// ## 사용 예시
///
/// ```swift
/// // Mock 생성
/// let user = UserDTO.mock()
///
/// // Fixture 생성
/// let fixedUser = UserDTO.fixture()
///
/// // 여러 개 생성
/// let users = UserDTO.mockArray(count: 10)
///
/// // 검증
/// user.assertValid()
/// ```
public protocol TestableDTO {
    /// 랜덤 값으로 테스트 데이터 생성
    ///
    /// 매 호출마다 다른 값을 생성합니다.
    /// 테스트 독립성을 보장하고 엣지 케이스를 발견하는 데 유용합니다.
    ///
    /// - Returns: 랜덤 값으로 채워진 인스턴스
    static func mock() -> Self

    /// 고정 값으로 테스트 데이터 생성
    ///
    /// 항상 동일한 값을 반환합니다.
    /// fixtureJSON이 제공된 경우 해당 JSON을 디코딩하여 사용하고,
    /// 없는 경우 타입별 기본값을 사용합니다.
    ///
    /// - Returns: 고정 값으로 채워진 인스턴스
    static func fixture() -> Self

    /// 여러 개의 Mock 데이터 생성
    ///
    /// - Parameter count: 생성할 Mock 개수 (기본값: 매크로 설정의 defaultArrayCount)
    /// - Returns: Mock 인스턴스 배열
    static func mockArray(count: Int) -> [Self]

    /// 데이터 유효성 검증
    ///
    /// 데이터가 비즈니스 규칙을 만족하는지 검증합니다.
    /// - ID 필드: 양수 검증
    /// - Email 필드: @ 및 . 포함 검증
    /// - String 필드: 비어있지 않음 검증
    ///
    /// - Throws: 검증 실패 시 assert로 크래시
    func assertValid() throws
}

// MARK: - @ResponseTestable 매크로

/// Codable 응답 모델에 테스트 데이터 생성 및 검증 기능을 추가하는 매크로
///
/// 이 매크로는 DTO 타입에 테스트에 필요한 Mock 생성 및 검증 메서드를 자동으로 추가합니다.
/// `@ResponseDocument` 매크로와 함께 사용하여 문서화와 테스트를 동시에 지원할 수 있습니다.
///
/// ## 주요 기능
///
/// 1. **Mock 데이터 생성**: `mock()`, `fixture()`, `mockArray()`
/// 2. **Builder 패턴**: 커스텀 테스트 데이터 생성 (옵션)
/// 3. **자동 검증**: `assertValid()`로 데이터 유효성 확인
/// 4. **TestableDTO 프로토콜 자동 채택**
///
/// ## 기본 사용법
///
/// ```swift
/// @ResponseTestable
/// struct UserDTO: Codable, Sendable {
///     let id: Int
///     let name: String
///     let email: String
/// }
///
/// // 사용 - mock()과 fixture()는 독립적으로 동작
/// let user = UserDTO.mock()           // 매번 다른 랜덤 데이터
/// let fixed = UserDTO.fixture()       // 항상 동일한 고정 데이터
/// let users = UserDTO.mockArray(count: 10)  // 10개의 랜덤 데이터 배열
/// user.assertValid()                  // 데이터 유효성 검증
/// ```
///
/// ## fixtureJSON 사용
///
/// `fixture()` 메서드에서 사용할 고정 JSON을 제공합니다.
///
/// ```swift
/// @ResponseTestable(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "John Doe",
///       "email": "john@example.com"
///     }
///     """
/// )
/// struct UserDTO: Codable, Sendable {
///     let id: Int
///     let name: String
///     let email: String
/// }
///
/// // 사용 - 두 메서드 모두 사용 가능
/// let random = UserDTO.mock()       // 랜덤 데이터
/// let fixed = UserDTO.fixture()     // fixtureJSON 기반 고정 데이터
/// ```
///
/// ## Builder 패턴 사용
///
/// 특정 필드만 커스터마이징하고 나머지는 fixture 값을 사용할 수 있습니다.
///
/// ```swift
/// @ResponseTestable(includeBuilder: true)
/// struct UserDTO: Codable, Sendable {
///     let id: Int
///     let name: String
///     let email: String
/// }
///
/// // 하이브리드 패턴 - 일부만 고정, 나머지는 fixture 값
/// let customUser = UserDTO.builder()
///     .with(id: 999)
///     .with(name: "Custom Name")
///     .build()
/// // email은 fixture() 값 사용
/// ```
///
/// ## 동일 타입에서 random과 fixture 동시 사용
///
/// `mock()`과 `fixture()`는 독립적으로 동작하므로 같은 타입에서 모두 사용 가능합니다.
///
/// ```swift
/// @ResponseTestable(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "John Doe"
///     }
///     """
/// )
/// struct UserDTO: Codable, Sendable {
///     let id: Int
///     let name: String
/// }
///
/// // Pattern 1: 완전 랜덤 (테스트 독립성)
/// let user1 = UserDTO.mock()
/// let user2 = UserDTO.mock()
/// #expect(user1.id != user2.id)  // ✅ 매번 다른 값
///
/// // Pattern 2: 완전 고정 (스냅샷 테스트)
/// let fixed1 = UserDTO.fixture()
/// let fixed2 = UserDTO.fixture()
/// #expect(fixed1.id == fixed2.id)  // ✅ 항상 동일한 값
///
/// // Pattern 3: 혼합 사용
/// let random = UserDTO.mock()      // 랜덤
/// let fixed = UserDTO.fixture()    // 고정
/// let custom = UserDTO.builder()   // 하이브리드
///     .with(id: 999)
///     .build()
/// ```
///
/// ## 중첩 DTO 지원
///
/// 배열이나 중첩된 커스텀 타입도 자동으로 처리됩니다.
///
/// ```swift
/// @ResponseTestable
/// struct PostDTO: Codable, Sendable {
///     let id: Int
///     let title: String
///     let comments: [CommentDTO]  // 2~5개의 랜덤 Comment 생성
/// }
///
/// let post = PostDTO.mock()
/// // post.comments는 자동으로 CommentDTO.mock()으로 채워짐
/// ```
///
/// ## @ResponseDocument와 함께 사용
///
/// ⚠️ **Deprecated**: `@ResponseDocument`는 더 이상 필요하지 않습니다.
/// `@ResponseTestable`이 `jsonSample` 프로퍼티도 생성합니다.
///
/// ```swift
/// // Before (v1.2.6)
/// @ResponseDocument(fixtureJSON: "...")
/// @ResponseTestable
/// struct UserDTO: Codable { }
///
/// // After (v1.3.0)
/// @ResponseTestable(fixtureJSON: "...")
/// struct UserDTO: Codable { }
///
/// // 사용 - 모든 기능 통합
/// let random = UserDTO.mock()      // 랜덤
/// let fixed = UserDTO.fixture()    // 고정
/// let json = UserDTO.jsonSample    // 문서화용 JSON ✅
/// ```
///
/// ## 파라미터 설명
///
/// - Parameter fixtureJSON: `fixture()` 메서드에서 사용할 고정 JSON 문자열
///   - `nil`이면 타입별 기본값 사용 (Int: 1, String: "Test String")
///   - `@ResponseDocument`의 fixtureJSON 자동 감지
///
/// - Parameter includeBuilder: Builder 패턴 포함 여부 (기본값: `true`)
///   - `true`: `builder()` 메서드 및 `{TypeName}Builder` 타입 생성
///   - `false`: Builder 미생성 (심플한 DTO에 적합)
///
/// - Parameter defaultArrayCount: `mockArray()` 기본 개수 (기본값: `5`)
///   - `mockArray()` 호출 시 count 생략하면 이 값 사용
///
/// - Parameter generateDocumentation: OpenAPI 문서용 `jsonSample` 생성 여부 (기본값: `true`)
///   - `true`: `static var jsonSample: String` 프로퍼티 생성
///   - `false`: 문서화 프로퍼티 미생성 (테스트만 필요한 경우)
///
/// ## 지원하는 타입
///
/// ### 기본 타입
/// - 정수: `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
/// - 실수: `Double`, `Float`, `CGFloat`
/// - 문자열: `String`
/// - 불린: `Bool`
/// - 날짜: `Date`, `UUID`
/// - 기타: `URL`, `Decimal`, `Data`
///
/// ### 컬렉션 타입
/// - 배열: `[Element]` (2~5개의 랜덤 요소)
/// - 딕셔너리: `[Key: Value]` (빈 딕셔너리)
/// - Set: `Set<Element>` (2~5개의 랜덤 요소)
///
/// ### 커스텀 타입
/// - 중첩 DTO: 자동으로 `.mock()` 호출
/// - Optional: 50% 확률로 `nil` 또는 값
///
/// ## 특수 필드명 인식
///
/// 필드명에 따라 적절한 Mock 데이터를 생성합니다:
///
/// - **email**: `"mock123@example.com"` 형식
/// - **url**: `"https://example.com/uuid"` 형식
/// - **id**: 양수 검증 추가
///
/// ## 주의사항
///
/// 1. **Codable 준수 필수**: 타입이 `Codable`을 준수해야 합니다.
/// 2. **struct 전용**: `class`, `enum`, `actor`에는 사용할 수 없습니다.
/// 3. **fixtureJSON 검증**: 잘못된 JSON은 런타임 에러 (`fatalError`)를 발생시킵니다.
/// 4. **순환 참조 주의**: 중첩 DTO가 순환 참조하면 무한 루프 발생 가능
///
/// ## 생성되는 멤버
///
/// ```swift
/// // Mock 생성 (항상 랜덤 값)
/// public static func mock() -> Self
///
/// // Fixture 생성 (항상 고정 값)
/// public static func fixture() -> Self
///
/// // 배열 생성 (랜덤 값 배열)
/// public static func mockArray(count: Int = defaultArrayCount) -> [Self]
///
/// // 검증
/// public func assertValid()
///
/// // OpenAPI 문서용 JSON (generateDocumentation: true인 경우)
/// public static var jsonSample: String
///
/// // Builder (includeBuilder: true인 경우)
/// public static func builder() -> {TypeName}Builder
/// public struct {TypeName}Builder: Sendable {
///     public func with({propertyName}: {PropertyType}) -> Self
///     public func build() -> {TypeName}
/// }
/// ```
///
/// ## Extension
///
/// ```swift
/// extension {TypeName}: TestableDTO {
/// }
/// ```
///
@attached(
    member,
    names: named(mock), named(fixture), named(builder), named(mockArray),
    named(assertValid), named(jsonSample), arbitrary
)
@attached(extension, conformances: TestableDTO)
public macro ResponseTestable(
    fixtureJSON: String? = nil,
    includeBuilder: Bool = true,
    defaultArrayCount: Int = 5,
    generateDocumentation: Bool = true
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "ResponseTestableMacroImpl"
)
