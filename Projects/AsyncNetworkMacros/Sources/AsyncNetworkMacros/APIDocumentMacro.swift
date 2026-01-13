//
//  APIDocumentMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

/// API Request에 문서화 메타데이터를 추가하는 매크로
///
/// 이 매크로는 `@APIRequest`와 함께 사용하여 API Playground UI 및 OpenAPI 문서 생성을 위한
/// 메타데이터를 생성합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     baseURL: "https://jsonplaceholder.typicode.com",
///     path: "/posts",
///     method: .get
/// )
/// @APIDocument(
///     title: "Get all posts",
///     description: """
///     JSONPlaceholder에서 모든 포스트를 가져옵니다.
///
///     기능:
///     • 페이지네이션 지원
///     • 사용자별 필터링
///     """,
///     tags: ["Posts", "Read"]
/// )
/// struct GetAllPostsRequest {
///     @QueryParameter var userId: Int?
///     @QueryParameter(key: "_limit") var limit: Int?
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// 위 코드는 다음과 같이 확장됩니다:
///
/// ```swift
/// struct GetAllPostsRequest {
///     @QueryParameter var userId: Int?
///     @QueryParameter(key: "_limit") var limit: Int?
///
///     // @APIRequest가 생성
///     typealias Response = [Post]
///     var baseURLString: String { "https://jsonplaceholder.typicode.com" }
///     var path: String { "/posts" }
///     var method: HTTPMethod { .get }
///
///     // @APIDocument가 생성
///     public static var metadata: EndpointMetadata {
///         EndpointMetadata(
///             id: "GetAllPostsRequest",
///             title: "Get all posts",
///             description: """
///             JSONPlaceholder에서 모든 포스트를 가져옵니다.
///
///             기능:
///             • 페이지네이션 지원
///             • 사용자별 필터링
///             """,
///             method: "get",
///             path: "/posts",
///             baseURLString: "https://jsonplaceholder.typicode.com",
///             headers: [:],
///             tags: ["Posts", "Read"],
///             parameters: ["userId", "limit"],
///             responseTypeName: "[Post]"
///         )
///     }
/// }
///
/// extension GetAllPostsRequest: APIRequest {
/// }
///
/// // @APIDocument가 DocumentableAPIRequest 채택 추가
/// extension GetAllPostsRequest: DocumentableAPIRequest {
/// }
/// ```
///
/// ## 주의사항
///
/// - `@APIRequest` 매크로가 **먼저** 선언되어야 합니다
/// - `@APIRequest` 없이 `@APIDocument`만 사용하면 컴파일 에러 발생
/// - `title`, `description`, `tags`는 모두 선택적 파라미터입니다
///
/// ## API Playground 연동
///
/// 생성된 `metadata`는 다음과 같이 사용됩니다:
///
/// ```swift
/// // APIRequestCatalog.swift
/// enum APIRequestCatalog {
///     static let all: [EndpointMetadata] = [
///         GetAllPostsRequest.metadata,  // ← @APIDocument가 생성
///         // ...
///     ]
/// }
/// ```
///
/// ## OpenAPI 연동
///
/// `metadata`의 정보는 OpenAPI 스펙 생성 시 자동으로 사용됩니다:
/// - `title` → OpenAPI `summary`
/// - `description` → OpenAPI `description`
/// - `tags` → OpenAPI `tags`
/// - `path`, `method` → OpenAPI paths
@attached(member, names: named(metadata))
@attached(extension, conformances: DocumentableAPIRequest)
public macro APIDocument(
    title: String = "",
    description: String = "",
    tags: [String] = []
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "APIDocumentMacroImpl"
)
