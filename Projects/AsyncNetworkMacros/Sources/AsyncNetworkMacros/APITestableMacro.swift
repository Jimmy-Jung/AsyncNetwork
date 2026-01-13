//
//  APITestableMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

/// API Request에 테스트 Mock 응답 생성 기능을 추가하는 매크로
///
/// 이 매크로는 `@APIRequest`와 함께 사용하여 테스트 시나리오별 Mock 응답을 생성합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @APIRequest(
///     response: PostDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .get
/// )
/// @APITestable(
///     scenarios: [.success, .notFound, .serverError],
///     errorExamples: [
///         "404": """{"error": "Post not found", "code": "POST_NOT_FOUND"}""",
///         "500": """{"error": "Internal server error"}"""
///     ]
/// )
/// struct GetPostRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// ```swift
/// struct GetPostRequest {
///     @PathParameter var id: Int
///
///     // @APIRequest가 생성
///     typealias Response = PostDTO
///     // ...
///
///     // @APITestable이 생성
///     enum MockScenario {
///         case success
///         case notFound
///         case serverError
///     }
///
///     static func mockResponse(for scenario: MockScenario) -> (Data?, URLResponse?, Error?) {
///         let url = URL(string: "https://api.example.com")!
///
///         switch scenario {
///         case .success:
///             let response = PostDTO.fixture()
///             let data = try? JSONEncoder().encode(response)
///             let httpResponse = HTTPURLResponse(
///                 url: url,
///                 statusCode: 200,
///                 httpVersion: nil,
///                 headerFields: ["Content-Type": "application/json"]
///             )
///             return (data, httpResponse, nil)
///         case .notFound:
///             let errorData = Data("""{"error": "Post not found", "code": "POST_NOT_FOUND"}""".utf8)
///             let httpResponse = HTTPURLResponse(url: url, statusCode: 404, ...)
///             return (errorData, httpResponse, nil)
///         case .serverError:
///             let errorData = Data("""{"error": "Internal server error"}""".utf8)
///             let httpResponse = HTTPURLResponse(url: url, statusCode: 500, ...)
///             return (errorData, httpResponse, nil)
///         }
///     }
/// }
/// ```
///
/// ## Swift Testing과 함께 사용
///
/// ```swift
/// import Testing
/// @testable import YourModule
///
/// @Test("성공 시나리오")
/// func testSuccess() async throws {
///     let request = GetPostRequest(id: 1)
///     let (data, response, error) = GetPostRequest.mockResponse(for: .success)
///
///     #expect(error == nil)
///     #expect((response as? HTTPURLResponse)?.statusCode == 200)
///
///     let post = try JSONDecoder().decode(PostDTO.self, from: data!)
///     #expect(post.id == 1)
/// }
///
/// @Test("Not Found 시나리오")
/// func testNotFound() {
///     let (data, response, error) = GetPostRequest.mockResponse(for: .notFound)
///
///     #expect(error == nil)
///     #expect((response as? HTTPURLResponse)?.statusCode == 404)
///
///     let errorJSON = try? JSONDecoder().decode([String: String].self, from: data!)
///     #expect(errorJSON?["code"] == "POST_NOT_FOUND")
/// }
/// ```
///
/// ## 주의사항
///
/// - `@APIRequest` 매크로가 **먼저** 선언되어야 합니다
/// - `Response` 타입이 `Codable`을 준수하고 `.fixture()` 메서드가 있어야 합니다
/// - `scenarios`에 정의된 케이스는 자동으로 `MockScenario` enum에 추가됩니다
/// - `errorExamples`의 키는 HTTP 상태 코드 문자열입니다 ("404", "500" 등)
@attached(member, names: named(MockScenario), named(mockResponse))
public macro APITestable(
    scenarios: [TestScenario] = [],
    errorExamples: [String: String] = [:]
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "APITestableMacroImpl"
)

/// 테스트 시나리오 타입
public enum TestScenario {
    /// 성공 응답 (200 OK)
    case success
    /// 클라이언트 에러 (4xx)
    case clientError
    /// 서버 에러 (5xx)
    case serverError
    /// 네트워크 에러
    case networkError
    /// 타임아웃
    case timeout
    /// 잘못된 응답 (Invalid JSON)
    case invalidResponse
    /// 인증 실패 (401)
    case unauthorized
    /// 리소스 없음 (404)
    case notFound
}
