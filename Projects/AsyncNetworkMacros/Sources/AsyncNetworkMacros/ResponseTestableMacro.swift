//
//  ResponseTestableMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

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
/// @ResponseTestable 매크로를 적용한 타입이 자동으로 채택합니다
public protocol TestableDTO {
    /// 랜덤 값으로 테스트 데이터 생성
    static func mock() -> Self

    /// 고정 값으로 테스트 데이터 생성
    static func fixture() -> Self

    /// 여러 개의 Mock 데이터 생성
    static func mockArray(count: Int) -> [Self]

    /// 데이터 검증
    func assertValid() throws
}

/// Codable 응답 모델에 테스트 데이터 생성 및 검증 기능을 추가하는 매크로
///
/// 이 매크로는 `@Response`와 함께 사용하여 테스트에서 사용할 Mock 데이터를 생성합니다.
/// 기존 `@TestableDTO`와 동일한 기능을 제공하지만, 책임이 명확히 분리되어 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// @Response
/// @ResponseTestable(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "title": "Test Post"
///     }
///     """,
///     includeBuilder: true
/// )
/// struct PostDTO: Codable {
///     let id: Int
///     let title: String
/// }
/// ```
///
/// ## 생성되는 메서드
///
/// - `static func mock() -> Self`: 랜덤 값으로 생성
/// - `static func fixture() -> Self`: 고정 값으로 생성
/// - `static func mockArray(count: Int) -> [Self]`: 여러 개 생성
/// - `func assertValid() throws`: 데이터 검증
/// - `static func builder() -> PostDTOBuilder`: Builder 패턴 (옵션)
@attached(member, names: named(mock), named(fixture), named(builder), named(mockArray), named(assertValid), arbitrary)
@attached(extension, conformances: TestableDTO)
public macro ResponseTestable(
    mockStrategy: MockStrategy = .random,
    fixtureJSON: String? = nil,
    includeBuilder: Bool = true,
    defaultArrayCount: Int = 5
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "ResponseTestableMacroImpl"
)
