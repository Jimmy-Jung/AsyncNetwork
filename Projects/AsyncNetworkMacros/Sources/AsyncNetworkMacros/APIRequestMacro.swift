//
//  APIRequestMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/02.
//

@_exported import AsyncNetworkCore

/// APIRequest 프로토콜 채택 시 필요한 보일러플레이트 프로퍼티를 자동 생성하는 매크로
///
/// 이 매크로를 사용하면 다음 프로퍼티들이 자동으로 생성됩니다:
/// - `typealias Response`: 응답 타입 별칭
/// - `baseURLString`: 베이스 URL 문자열 (선택적)
/// - `path`: API 엔드포인트 경로
/// - `method`: HTTP 메서드 (GET, POST, PUT, DELETE 등)
///
/// ## 기본 사용법
///
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     baseURL: "https://jsonplaceholder.typicode.com",
///     path: "/posts",
///     method: .get
/// )
/// struct GetPostsRequest {
///     @HeaderField(key: .contentType) var contentType: String? = "application/json"
///     @QueryParameter var userId: Int?
///     @QueryParameter var page: Int = 1
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// 위 코드는 다음과 같이 확장됩니다:
///
/// ```swift
/// struct GetPostsRequest {
///     @HeaderField(key: .contentType) var contentType: String? = "application/json"
///     @QueryParameter var userId: Int?
///     @QueryParameter var page: Int = 1
///
///     typealias Response = [Post]
///
///     var baseURLString: String {
///         "https://jsonplaceholder.typicode.com"
///     }
///
///     var path: String {
///         "/posts"
///     }
///
///     var method: HTTPMethod {
///         .get
///     }
/// }
///
/// extension GetPostsRequest: APIRequest {
/// }
/// ```
///
/// ## 문서화 및 테스트 기능
///
/// 문서화 메타데이터와 테스트 Mock 응답이 필요한 경우, 분리된 매크로를 함께 사용하세요:
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .get
/// )
/// @APIDocument(
///     title: "Get post by ID",
///     description: "Retrieve a single post by its ID",
///     tags: ["Posts", "Read"]
/// )
/// @APITestable(
///     scenarios: [.success, .notFound, .serverError],
///     errorExamples: [
///         "404": """{"error": "Post not found"}""",
///         "500": """{"error": "Internal server error"}"""
///     ]
/// )
/// struct GetPostRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ## 동적 베이스 URL
///
/// `baseURL` 파라미터는 필수이지만, 문자열 리터럴 대신 표현식을 사용할 수 있습니다:
///
/// ```swift
/// let apiBaseURL = "https://api.example.com"
///
/// @APIRequest(
///     response: Post.self,
///     baseURL: apiBaseURL,  // 상수 참조
///     path: "/posts/1",
///     method: .get
/// )
/// struct GetPostRequest {
/// }
/// ```
///
/// 또는 이미 선언된 `baseURLString` 프로퍼티가 있다면 매크로가 생성하지 않습니다:
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",  // metadata용으로만 사용
///     path: "/posts/1",
///     method: .get
/// )
/// struct GetPostRequest {
///     let environment: Environment
///
///     // 이미 선언되어 있으면 매크로가 생성하지 않음
///     var baseURLString: String {
///         environment.baseURL
///     }
/// }
/// ```
///
/// ## 동적 경로 파라미터
///
/// `path` 프로퍼티를 직접 구현하여 동적 경로를 생성할 수 있습니다:
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .put
/// )
/// struct UpdatePostRequest {
///     let id: Int
///
///     var path: String {
///         "/posts/\(id)"
///     }
///
///     @RequestBody var body: PostBody
/// }
/// ```
///
/// ## HTTP 헤더 설정
///
/// 헤더는 `@HeaderField` 또는 `@CustomHeader` 프로퍼티 래퍼를 사용합니다:
///
/// ```swift
/// @APIRequest(
///     response: User.self,
///     baseURL: "https://api.example.com",
///     path: "/user/me",
///     method: .get
/// )
/// struct GetCurrentUserRequest {
///     @HeaderField(key: .authorization) var authorization: String?
///     @HeaderField(key: .contentType) var contentType: String? = "application/json"
///     @CustomHeader("X-Request-ID") var requestId: String?
/// }
/// ```
///
/// ## Property Wrappers 통합
///
/// 다음 Property Wrapper들과 함께 사용할 수 있습니다:
/// - `@QueryParameter`: URL 쿼리 파라미터
/// - `@PathParameter`: URL 경로 파라미터
/// - `@HeaderField`: 타입 안전한 HTTP 헤더 (HTTPHeaders.HeaderKey 사용)
/// - `@CustomHeader`: 커스텀 HTTP 헤더
/// - `@RequestBody`: 요청 바디
/// - `@FormData`: Multipart Form Data
///
/// ## 주의사항
///
/// - 이 매크로는 `struct`에만 적용할 수 있습니다.
/// - 필수 파라미터: `response`, `baseURL`, `path`, `method`
/// - 이미 선언된 프로퍼티는 매크로가 생성하지 않습니다.
/// - `method` 파라미터는 HTTPMethod enum case로 지정합니다 (.get, .post, .put, .delete, .patch, .head, .options)
/// - HTTP 헤더는 매크로 파라미터 대신 `@HeaderField` 프로퍼티 래퍼를 사용하세요
/// - 문서화가 필요하면 `@APIDocument` 매크로를 함께 사용하세요
/// - 테스트 Mock이 필요하면 `@APITestable` 매크로를 함께 사용하세요
@attached(member, names:
    named(Response),
    named(baseURLString),
    named(path),
    named(method),
    named(task))
@attached(extension, conformances: APIRequest)
public macro APIRequest(
    response: Any.Type,
    baseURL: String,
    path: String,
    method: HTTPMethod,
    errorResponses: [Int: Any.Type] = [:]
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "APIRequestMacroImpl"
)
