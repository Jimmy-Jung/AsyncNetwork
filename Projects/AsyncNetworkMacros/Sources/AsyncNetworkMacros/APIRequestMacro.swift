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
/// - `headers`: HTTP 헤더 (선택적)
/// - `metadata`: 엔드포인트 메타데이터 (DocKit용)
///
/// ## 사용 예시
///
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     title: "Get all posts",
///     description: "Retrieve a list of all posts",
///     baseURL: "https://jsonplaceholder.typicode.com",
///     path: "/posts",
///     method: "get",
///     headers: ["Content-Type": "application/json"],
///     tags: ["Posts", "Read"],
///     responseExample: "[{\"id\": 1, \"title\": \"Hello\"}]"
/// )
/// struct GetPostsRequest {
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
///
///     var headers: [String: String]? {
///         ["Content-Type": "application/json"]
///     }
///
///     static var metadata: EndpointMetadata {
///         EndpointMetadata(
///             id: "GetPostsRequest",
///             title: "Get all posts",
///             description: "Retrieve a list of all posts",
///             method: "get",
///             path: "/posts",
///             baseURLString: "https://jsonplaceholder.typicode.com",
///             headers: ["Content-Type": "application/json"],
///             tags: ["Posts", "Read"],
///             parameters: [],
///             requestBodyExample: nil,
///             responseExample: "[{\"id\": 1, \"title\": \"Hello\"}]",
///             responseTypeName: "[Post]"
///         )
///     }
/// }
///
/// extension GetPostsRequest: APIRequest {
/// }
/// ```
///
/// ## 동적 베이스 URL
///
/// `baseURL` 파라미터를 생략하면 구조체에서 직접 `baseURLString` 프로퍼티를 구현할 수 있습니다:
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     title: "Get a post",
///     path: "/posts/1",
///     method: "get"
/// )
/// struct GetPostRequest {
///     let environment: Environment
///
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
///     title: "Update a post",
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: "put"
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
/// ## Property Wrappers 통합
///
/// 다음 Property Wrapper들과 함께 사용할 수 있습니다:
/// - `@QueryParameter`: URL 쿼리 파라미터
/// - `@PathParameter`: URL 경로 파라미터
/// - `@HeaderParameter`: HTTP 헤더
/// - `@RequestBody`: 요청 바디
/// - `@FormData`: Multipart Form Data
///
/// ## 주의사항
///
/// - 이 매크로는 `struct`에만 적용할 수 있습니다.
/// - 필수 파라미터: `response`, `title`, `path`, `method`
/// - 이미 선언된 프로퍼티는 매크로가 생성하지 않습니다.
/// - `method` 파라미터는 문자열로 지정합니다 ("get", "post", "put", "delete", "patch", "head", "options")
@attached(member, names:
    named(Response),
    named(baseURLString),
    named(path),
    named(method),
    named(headers),
    named(task),
    named(metadata))
@attached(extension, conformances: APIRequest)
public macro APIRequest(
    response: Any.Type,
    title: String,
    description: String = "",
    baseURL: String? = nil,
    path: String,
    method: String,
    headers: [String: String] = [:],
    tags: [String] = [],
    requestBodyExample: String? = nil,
    responseExample: String? = nil
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "APIRequestMacroImpl"
)
