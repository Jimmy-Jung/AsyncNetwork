//
//  TestableSemerMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/06.
//

@_exported import AsyncNetworkCore

/// @APIRequest와 연동하여 API 테스트 시나리오를 자동 생성하는 매크로
///
/// **⚠️ Deprecated**: 이 매크로는 `@APIRequest`에 통합되었습니다.
/// `@APIRequest`의 `testScenarios`, `errorExamples` 파라미터를 사용하세요.
///
/// 이 매크로를 사용하면 다음이 자동으로 생성됩니다:
/// - `enum MockScenario`: 테스트 시나리오 케이스
/// - `static func mockResponse(for:) -> (Data?, URLResponse?, Error?)`: Mock 응답 제공자
/// - `struct Tests`: Swift Testing 기반 테스트 스위트
///
/// ## 마이그레이션 가이드
///
/// **이전 코드:**
/// ```swift
/// @APIRequest(...)
/// @TestableSchemer(
///     scenarios: [.success, .notFound],
///     errorExamples: ["404": """{"error": "Not found"}"""]
/// )
/// struct GetPostRequest { }
/// ```
///
/// **새 코드:**
/// ```swift
/// @APIRequest(
///     ...,
///     testScenarios: [.success, .notFound],
///     errorExamples: ["404": """{"error": "Not found"}"""]
/// )
/// struct GetPostRequest { }
/// ```
///
/// ## 기본 사용법
///
/// ```swift
/// @APIRequest(
///     response: User.self,
///     title: "사용자 조회",
///     baseURL: "https://api.example.com",
///     path: "/users/:id",
///     method: .get
/// )
/// @TestableSchemer(
///     scenarios: [.success, .notFound, .serverError],
///     errorExamples: [
///         "404": """
///         {
///           "error": "User not found",
///           "code": "USER_NOT_FOUND"
///         }
///         """,
///         "500": """
///         {
///           "error": "Internal server error"
///         }
///         """
///     ]
/// )
/// struct GetUserRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ## OpenAPI 연동
///
/// `errorExamples`에 정의된 값은 OpenAPI 스펙 생성 시 자동으로 에러 응답 `example`로 사용됩니다:
///
/// ```json
/// {
///   "paths": {
///     "/users/{id}": {
///       "get": {
///         "responses": {
///           "200": {
///             "content": {
///               "application/json": {
///                 "example": { ... }  // User의 fixtureJSON 자동 사용
///               }
///             }
///           },
///           "404": {
///             "description": "Not Found",
///             "content": {
///               "application/json": {
///                 "example": {
///                   "error": "User not found",
///                   "code": "USER_NOT_FOUND"
///                 }
///               }
///             }
///           },
///           "500": {
///             "description": "Internal Server Error",
///             "content": {
///               "application/json": {
///                 "example": {
///                   "error": "Internal server error"
///                 }
///               }
///             }
///           }
///         }
///       }
///     }
///   }
/// }
/// ```
///
/// ## 생성되는 테스트 사용 예시
///
/// ```swift
/// import Testing
/// @testable import YourModule
///
/// // 자동 생성된 테스트 실행
/// @Test("GetUserRequest 성공 시나리오")
/// func testGetUserSuccess() async throws {
///     MockURLProtocol.mockResponse = GetUserRequest.mockResponse(for: .success)
///
///     let service = NetworkService(configuration: NetworkConfiguration(
///         urlSessionConfiguration: .ephemeral
///     ))
///     let request = GetUserRequest(id: 1)
///     let user = try await service.request(request)
///
///     #expect(user.id == 1)
/// }
///
/// // 또는 자동 생성된 Tests 사용
/// let tests = GetUserRequest.Tests()
/// try await tests.testSuccess()
/// ```
///
/// ## 옵션
///
/// - `scenarios`: 포함할 테스트 시나리오 (기본값: `.success`, `.clientError`, `.serverError`)
/// - `includeRetryTests`: 재시도 테스트 포함 여부 (기본값: `true`)
/// - `errorExamples`: OpenAPI 에러 응답 예제 (status code: JSON)
/// - `includePerformanceTests`: 성능 테스트 포함 여부 (기본값: `false`)
///
/// ## 주의사항
///
/// - 이 매크로는 `@APIRequest`와 함께 사용해야 합니다.
/// - `errorExamples`의 키는 HTTP 상태 코드 문자열이어야 합니다 (예: "404", "500").
/// - 성공 응답(200)은 Response 타입의 `@TestableDTO.fixtureJSON`을 자동으로 사용합니다.
@available(*, deprecated, message: "Use @APIRequest with testScenarios and errorExamples parameters instead")
@attached(member, names:
    named(MockScenario),
    named(mockResponse),
    named(Tests),
    arbitrary)
public macro TestableSchemer(
    /// 포함할 테스트 시나리오
    scenarios: [TestScenario] = [.success, .clientError, .serverError],

    /// 재시도 테스트 포함 여부
    includeRetryTests: Bool = true,

    /// OpenAPI 에러 응답 예제 (HTTP 상태 코드: JSON)
    /// 예: ["404": """{"error": "Not found"}"""]
    errorExamples: [String: String] = [:],

    /// 성능 테스트 포함 여부
    includePerformanceTests: Bool = false
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "TestableSemerMacroImpl"
)

// Note: TestScenario enum은 APIRequestMacro.swift에 정의되어 있습니다.
