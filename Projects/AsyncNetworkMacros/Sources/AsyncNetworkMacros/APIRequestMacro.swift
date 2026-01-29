//
//  APIRequestMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/02.
//

@_exported import AsyncNetworkCore

/// APIRequest 프로토콜 채택 시 필요한 보일러플레이트 코드를 자동 생성하는 매크로
///
/// `@APIRequest` 매크로는 Swift Macro 시스템을 활용하여 네트워크 요청에 필요한 반복적인 코드를 제거합니다.
/// AsyncNetwork 프레임워크의 핵심 매크로로, 타입 안전한 API 요청 정의를 가능하게 합니다.
///
/// ## 자동 생성되는 프로퍼티
///
/// - `typealias Response`: 응답 타입 별칭
/// - `baseURLString`: API 베이스 URL (문자열 리터럴 또는 표현식)
/// - `path`: API 엔드포인트 경로 (정적 또는 동적)
/// - `method`: HTTP 메서드 (GET, POST, PUT, DELETE 등)
/// - `metadata`: API 문서화를 위한 메타데이터 (선택적)
///
/// ## 기본 사용법
///
/// 가장 간단한 형태의 API 요청 정의:
///
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     baseURL: "https://jsonplaceholder.typicode.com",
///     path: "/posts",
///     method: .get
/// )
/// struct GetPostsRequest {
///     @QueryParameter var userId: Int?
///     @QueryParameter var page: Int = 1
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// 위 코드는 컴파일 타임에 다음과 같이 확장됩니다:
///
/// ```swift
/// struct GetPostsRequest {
///     @QueryParameter var userId: Int?
///     @QueryParameter var page: Int = 1
///
///     // ✅ 자동 생성
///     typealias Response = [Post]
///
///     // ✅ 자동 생성
///     public var baseURLString: String {
///         "https://jsonplaceholder.typicode.com"
///     }
///
///     // ✅ 자동 생성
///     public var path: String {
///         "/posts"
///     }
///
///     // ✅ 자동 생성
///     public var method: HTTPMethod {
///         .get
///     }
///
///     // ✅ 자동 생성 (문서화용)
///     public static var metadata: EndpointMetadata {
///         EndpointMetadata(
///             id: "GetPostsRequest",
///             title: "",
///             description: "",
///             method: "GET",
///             path: "/posts",
///             baseURLString: "https://jsonplaceholder.typicode.com",
///             headers: [:],
///             tags: [],
///             parameters: ["userId", "page"],
///             responseTypeName: "[Post]"
///         )
///     }
/// }
///
/// // ✅ 자동으로 APIRequest 프로토콜 채택
/// extension GetPostsRequest: APIRequest {
/// }
/// ```
///
/// ## 동적 경로 파라미터 (@PathParameter)
///
/// 경로에 `{placeholder}` 구문을 사용하면 동적 경로가 자동 생성됩니다:
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .get
/// )
/// struct GetPostRequest {
///     @PathParameter var id: Int
/// }
///
/// // 생성된 path 프로퍼티:
/// // public var path: String {
/// //     "/posts/\(id)"
/// // }
/// ```
///
/// ### 선택적 경로 파라미터
///
/// `{id?}` 구문으로 선택적 파라미터를 정의할 수 있습니다:
///
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     baseURL: "https://api.example.com",
///     path: "/api/{version?}/posts",
///     method: .get
/// )
/// struct GetPostsRequest {
///     @PathParameter var version: String?
/// }
///
/// // version이 nil이면: "/api/posts"
/// // version이 "v2"면: "/api/v2/posts"
/// ```
///
/// ## 동적 베이스 URL
///
/// ### 방법 1: 상수/변수 참조
///
/// ```swift
/// enum Environment {
///     static let production = "https://api.example.com"
///     static let staging = "https://staging.example.com"
/// }
///
/// @APIRequest(
///     response: Post.self,
///     baseURL: Environment.production,  // ✅ 표현식 사용
///     path: "/posts",
///     method: .get
/// )
/// struct GetPostsRequest {
/// }
/// ```
///
/// ### 방법 2: 직접 구현 (매크로가 생성하지 않음)
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",  // metadata용으로만 사용
///     path: "/posts",
///     method: .get
/// )
/// struct GetPostsRequest {
///     let environment: Environment
///
///     // ✅ 이미 선언되어 있으면 매크로가 생성하지 않음
///     var baseURLString: String {
///         environment.baseURL
///     }
/// }
/// ```
///
/// ## HTTP 메서드별 사용 예시
///
/// ### POST 요청 (Create)
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts",
///     method: .post
/// )
/// struct CreatePostRequest {
///     @RequestBody var post: PostBody
///     @HeaderField(key: .authorization) var authorization: String?
/// }
/// ```
///
/// ### PUT 요청 (Update)
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .put
/// )
/// struct UpdatePostRequest {
///     @PathParameter var id: Int
///     @RequestBody var post: PostBody
/// }
/// ```
///
/// ### DELETE 요청
///
/// ```swift
/// @APIRequest(
///     response: EmptyResponse.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .delete
/// )
/// struct DeletePostRequest {
///     @PathParameter var id: Int
///     @HeaderField(key: .authorization) var authorization: String?
/// }
/// ```
///
/// ## Property Wrappers 통합
///
/// AsyncNetwork는 다양한 Property Wrapper를 제공합니다:
///
/// ### @QueryParameter - URL 쿼리 파라미터
///
/// ```swift
/// @APIRequest(...)
/// struct SearchRequest {
///     @QueryParameter var query: String          // 필수: ?query=...
///     @QueryParameter var page: Int = 1          // 기본값: ?page=1
///     @QueryParameter var sort: String?          // 선택적: nil이면 쿼리에서 제외
///     @QueryParameter(key: "per_page") var pageSize: Int = 20  // 커스텀 키
/// }
/// ```
///
/// ### @PathParameter - URL 경로 파라미터
///
/// ```swift
/// @APIRequest(path: "/users/{userId}/posts/{postId}", ...)
/// struct GetUserPostRequest {
///     @PathParameter var userId: Int
///     @PathParameter var postId: String
///     // 또는 커스텀 키: @PathParameter(key: "userId") var id: Int
/// }
/// ```
///
/// ### @HeaderField - 타입 안전한 HTTP 헤더
///
/// ```swift
/// @APIRequest(...)
/// struct AuthenticatedRequest {
///     @HeaderField(key: .authorization) var authorization: String?
///     @HeaderField(key: .contentType) var contentType: String? = "application/json"
///     @HeaderField(key: .accept) var accept: String? = "application/json"
///     @HeaderField(key: .userAgent) var userAgent: String? = "MyApp/1.0"
/// }
/// ```
///
/// ### @CustomHeader - 커스텀 HTTP 헤더
///
/// ```swift
/// @APIRequest(...)
/// struct CustomHeaderRequest {
///     @CustomHeader("X-Request-ID") var requestId: String?
///     @CustomHeader("X-API-Key") var apiKey: String
///     @CustomHeader("X-Client-Version") var clientVersion: String = "1.0.0"
/// }
/// ```
///
/// ### @RequestBody - JSON 요청 바디
///
/// ```swift
/// @APIRequest(method: .post, ...)
/// struct CreateUserRequest {
///     @RequestBody var user: UserBody
/// }
///
/// struct UserBody: Codable {
///     let name: String
///     let email: String
///     let age: Int
/// }
/// ```
///
/// ## 매크로 조합 사용
///
/// `@APIRequest`는 다른 매크로들과 함께 사용할 수 있습니다:
///
/// ### @APIDocument - API 문서화 메타데이터
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .get
/// )
/// @APIDocument(
///     title: "게시글 조회",
///     description: "ID로 단일 게시글을 조회합니다",
///     tags: ["Posts", "Read"]
/// )
/// struct GetPostRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ### @APITestable - 테스트 Mock 응답 자동 생성
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .get
/// )
/// @APITestable(
///     scenarios: [.success, .notFound, .serverError],
///     errorExamples: [
///         "404": """{"error": "Post not found", "code": "POST_NOT_FOUND"}""",
///         "500": """{"error": "Internal server error", "code": "INTERNAL_ERROR"}"""
///     ]
/// )
/// struct GetPostRequest {
///     @PathParameter var id: Int
/// }
///
/// // 테스트에서 사용:
/// let mockResponse = GetPostRequest.mockResponse(for: .notFound)
/// ```
///
/// ## 에러 응답 매핑
///
/// 특정 상태 코드에 대한 에러 응답 타입을 지정할 수 있습니다:
///
/// ```swift
/// @APIRequest(
///     response: Post.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}",
///     method: .get,
///     errorResponses: [
///         404: NotFoundError.self,
///         500: ServerError.self
///     ]
/// )
/// struct GetPostRequest {
///     @PathParameter var id: Int
/// }
/// ```
///
/// ## 고급 사용 패턴
///
/// ### 1. 프로토콜 기반 설정 공유
///
/// ```swift
/// protocol APIConfiguration {
///     static var baseURL: String { get }
/// }
///
/// enum Production: APIConfiguration {
///     static let baseURL = "https://api.example.com"
/// }
///
/// @APIRequest(
///     response: Post.self,
///     baseURL: Production.baseURL,
///     path: "/posts",
///     method: .get
/// )
/// struct GetPostsRequest {
/// }
/// ```
///
/// ### 2. 조건부 헤더
///
/// ```swift
/// @APIRequest(
///     response: User.self,
///     baseURL: "https://api.example.com",
///     path: "/user/me",
///     method: .get
/// )
/// struct GetCurrentUserRequest {
///     let token: String?
///
///     @HeaderField(key: .authorization) 
///     var authorization: String? {
///         token.map { "Bearer \($0)" }
///     }
/// }
/// ```
///
/// ### 3. 복잡한 쿼리 파라미터
///
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     baseURL: "https://api.example.com",
///     path: "/posts/search",
///     method: .get
/// )
/// struct SearchPostsRequest {
///     @QueryParameter var query: String
///     @QueryParameter var tags: [String]?              // ?tags=swift,ios
///     @QueryParameter(key: "created_after") var createdAfter: Date?
///     @QueryParameter var sortBy: SortField = .date
///     @QueryParameter var order: SortOrder = .desc
///     @QueryParameter var page: Int = 1
///     @QueryParameter(key: "per_page") var pageSize: Int = 20
/// }
/// ```
///
/// ## 제약사항 및 주의사항
///
/// ### ✅ 지원되는 경우
///
/// - `struct` 선언에만 적용 가능
/// - Property Wrapper와 함께 사용 가능
/// - 다른 매크로(`@APIDocument`, `@APITestable`)와 조합 가능
/// - 이미 선언된 프로퍼티는 매크로가 재생성하지 않음
///
/// ### ❌ 지원되지 않는 경우
///
/// - `class`, `enum`, `actor`에는 적용 불가
/// - `init` 메서드는 자동 생성되지 않음 (Swift의 memberwise initializer 사용)
/// - 동적 `method` 프로퍼티 생성 불가 (항상 고정 값)
///
/// ### 🔍 검증 및 제안
///
/// 매크로는 컴파일 타임에 다음을 검증하고 제안합니다:
///
/// - `@PathParameter` 프로퍼티 이름이 경로의 플레이스홀더와 일치하는지
/// - `@QueryParameter`가 적절한 HTTP 메서드에서 사용되는지
/// - `@RequestBody`가 POST/PUT/PATCH 메서드에서만 사용되는지
/// - 헤더 관련 프로퍼티에 `@HeaderField` 또는 `@CustomHeader`가 필요한지
///
/// ## 관련 매크로
///
/// - `@APIDocument`: API 문서화 메타데이터 추가
/// - `@APITestable`: 테스트 Mock 응답 자동 생성
/// - `@ResponseDocument`: 응답 타입 문서화
/// - `@ResponseTestable`: 응답 타입 테스트 데이터 생성
///
/// ## 성능 고려사항
///
/// - 매크로는 **컴파일 타임**에 코드를 생성하므로 **런타임 오버헤드 없음**
/// - 생성된 코드는 일반 Swift 코드와 동일한 성능
/// - Property Wrapper의 wrappedValue 접근은 인라인 최적화됨
///
@attached(member, names:
    named(Response),
    named(baseURLString),
    named(path),
    named(method),
    named(task),
    named(metadata))
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
