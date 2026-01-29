//
//  APIDocumentMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

/// API Request에 문서화 메타데이터를 추가하는 매크로
///
/// `@APIRequest`와 함께 사용하여 API 엔드포인트에 대한 풍부한 문서화 정보를 추가합니다.
/// 생성된 메타데이터는 API Playground UI, OpenAPI 스펙 생성, API 문서 자동화 등에 활용됩니다.
///
/// ## 주요 기능
///
/// - **API 문서 자동 생성**: OpenAPI 스펙으로 변환되어 Swagger UI 등에서 사용 가능
/// - **API Playground 지원**: 앱 내 API 테스트 UI에서 엔드포인트 정보 표시
/// - **타입 안전성**: 컴파일 타임에 문서 정합성 검증
/// - **특수문자 안전 처리**: 백슬래시, 따옴표, 개행 등 자동 이스케이프
///
/// ## 기본 사용 예시
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
///     • 페이지네이션 지원 (_limit 파라미터)
///     • 사용자별 필터링 (userId 파라미터)
///     • 정렬 및 검색 지원
///     """,
///     tags: ["Posts", "Read", "Public"]
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
///     // @APIRequest가 생성하는 코드
///     typealias Response = [Post]
///     var baseURLString: String { "https://jsonplaceholder.typicode.com" }
///     var path: String { "/posts" }
///     var method: HTTPMethod { .get }
///
///     // @APIDocument가 생성하는 메타데이터
///     public static var metadata: EndpointMetadata {
///         EndpointMetadata(
///             id: "GetAllPostsRequest",
///             title: "Get all posts",
///             description: """
///             JSONPlaceholder에서 모든 포스트를 가져옵니다.
///
///             기능:
///             • 페이지네이션 지원 (_limit 파라미터)
///             • 사용자별 필터링 (userId 파라미터)
///             • 정렬 및 검색 지원
///             """,
///             method: "GET",
///             path: "/posts",
///             baseURLString: "https://jsonplaceholder.typicode.com",
///             headers: [:],
///             tags: ["Posts", "Read", "Public"],
///             parameters: ["userId", "limit"],
///             responseTypeName: "[Post]"
///         )
///     }
/// }
///
/// extension GetAllPostsRequest: APIRequest {
/// }
///
/// // @APIDocument가 자동으로 추가하는 프로토콜 채택
/// extension GetAllPostsRequest: DocumentableAPIRequest {
/// }
/// ```
///
/// ## 파라미터 설명
///
/// ### title
/// - 타입: `String`
/// - 기본값: `""`
/// - 용도: API 엔드포인트의 제목 (OpenAPI `summary`로 매핑)
/// - 예시: `"Get all posts"`, `"Create new user"`
///
/// ### description
/// - 타입: `String`
/// - 기본값: `""`
/// - 용도: API 엔드포인트의 상세 설명 (OpenAPI `description`으로 매핑)
/// - 다중 라인 문자열 지원 (`"""..."""`)
/// - Markdown 문법 사용 가능
/// - 예시:
///   ```swift
///   description: """
///   사용자 정보를 조회합니다.
///
///   ## 권한
///   - 인증 필요: Yes
///   - 필요 권한: `user:read`
///
///   ## 응답 예시
///   성공 시 사용자 객체를 반환합니다.
///   """
///   ```
///
/// ### tags
/// - 타입: `[String]`
/// - 기본값: `[]`
/// - 용도: API 엔드포인트를 그룹화하는 태그 (OpenAPI `tags`로 매핑)
/// - Swagger UI에서 섹션으로 표시됨
/// - 예시: `["Users", "Admin", "v1"]`
///
/// ## 고급 사용 예시
///
/// ### 1. 특수문자가 포함된 문서화
///
/// 따옴표, 백슬래시, 개행 등 특수문자가 자동으로 이스케이프됩니다:
///
/// ```swift
/// @APIDocument(
///     title: "Get \"specific\" post",
///     description: "첫 번째 줄\n두 번째 줄\t탭으로 들여쓰기",
///     tags: ["Posts\\Category", "Read\"Only"]
/// )
/// ```
///
/// ### 2. 헤더 정보가 포함된 문서화
///
/// @HeaderField와 @CustomHeader의 기본값이 메타데이터에 자동 포함됩니다:
///
/// ```swift
/// @APIRequest(
///     response: PostDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/posts",
///     method: .get
/// )
/// @APIDocument(
///     title: "Get posts with custom headers",
///     description: "커스텀 헤더를 사용한 포스트 조회",
///     tags: ["Posts", "Advanced"]
/// )
/// struct GetPostsWithHeadersRequest {
///     @HeaderField(key: .authorization) var auth: String = "Bearer token"
///     @CustomHeader(key: "X-API-Version") var apiVersion: String = "2.0"
/// }
/// // 생성되는 metadata.headers = ["Authorization": "Bearer token", "X-API-Version": "2.0"]
/// ```
///
/// ### 3. Path/Query 파라미터 문서화
///
/// PropertyWrappers로 정의한 파라미터가 자동으로 추출됩니다:
///
/// ```swift
/// @APIRequest(
///     response: PostDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/posts/{id}/comments",
///     method: .get
/// )
/// @APIDocument(
///     title: "Get post comments",
///     description: "특정 포스트의 댓글 목록을 조회합니다",
///     tags: ["Posts", "Comments"]
/// )
/// struct GetPostCommentsRequest {
///     @PathParameter var id: String
///     @QueryParameter var page: Int?
///     @QueryParameter var limit: Int?
/// }
/// // 생성되는 metadata.parameters = ["id", "page", "limit"]
/// ```
///
/// ### 4. 다국어 문서화
///
/// ```swift
/// @APIDocument(
///     title: "사용자 조회",
///     description: """
///     사용자 ID로 사용자 정보를 조회합니다.
///
///     한글, English, 日本語 모두 지원됩니다.
///     """,
///     tags: ["사용자", "조회"]
/// )
/// ```
///
/// ## 제약사항 및 주의사항
///
/// ### 필수 조건
/// - ✅ `@APIRequest` 매크로가 **반드시 먼저** 선언되어야 합니다
/// - ✅ `struct` 타입에만 적용 가능합니다 (class, enum, actor 불가)
///
/// ### 사용 금지 패턴
///
/// ```swift
/// // ❌ 잘못된 예: @APIRequest가 없음
/// @APIDocument(title: "Test")
/// struct MyRequest { }
/// // 컴파일 에러: @APIDocument requires @APIRequest to be declared first.
///
/// // ❌ 잘못된 예: class에 적용
/// @APIRequest(...)
/// @APIDocument(...)
/// class MyRequest { }  // 컴파일 에러: @APIDocument can only be applied to a struct
///
/// // ❌ 잘못된 예: 순서가 바뀜
/// @APIDocument(...)  // @APIRequest가 먼저 와야 함
/// @APIRequest(...)
/// struct MyRequest { }
/// ```
///
/// ### 올바른 사용 패턴
///
/// ```swift
/// // ✅ 올바른 예: @APIRequest → @APIDocument 순서
/// @APIRequest(
///     response: PostDTO.self,
///     baseURL: "https://api.example.com",
///     path: "/posts",
///     method: .get
/// )
/// @APIDocument(
///     title: "Get posts",
///     description: "포스트 목록 조회",
///     tags: ["Posts"]
/// )
/// struct GetPostsRequest { }
///
/// // ✅ 올바른 예: 파라미터 생략 가능
/// @APIRequest(...)
/// @APIDocument()  // 모든 파라미터가 기본값을 가짐
/// struct MyRequest { }
/// ```
///
/// ## 생성된 메타데이터 활용
///
/// ### 1. API Playground에서 사용
///
/// API Playground UI에서 엔드포인트 목록을 표시할 때 사용:
///
/// ```swift
/// // APIRequestCatalog.swift
/// enum APIRequestCatalog {
///     static let all: [EndpointMetadata] = [
///         GetAllPostsRequest.metadata,
///         CreatePostRequest.metadata,
///         UpdatePostRequest.metadata,
///         DeletePostRequest.metadata,
///     ]
/// }
///
/// // PlaygroundView.swift
/// struct PlaygroundView: View {
///     var body: some View {
///         List(APIRequestCatalog.all, id: \.id) { endpoint in
///             VStack(alignment: .leading) {
///                 Text(endpoint.title)
///                     .font(.headline)
///                 Text(endpoint.description)
///                     .font(.caption)
///                 HStack {
///                     ForEach(endpoint.tags, id: \.self) { tag in
///                         Text(tag)
///                             .font(.caption2)
///                             .padding(4)
///                             .background(Color.blue.opacity(0.2))
///                             .cornerRadius(4)
///                     }
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// ### 2. OpenAPI 스펙 생성
///
/// OpenAPI 3.0 스펙으로 자동 변환:
///
/// ```swift
/// // OpenAPI 생성 스크립트
/// let metadata = GetAllPostsRequest.metadata
///
/// let openAPIPath = """
/// {
///   "\(metadata.path)": {
///     "\(metadata.method.lowercased())": {
///       "summary": "\(metadata.title)",
///       "description": "\(metadata.description)",
///       "tags": \(metadata.tags),
///       "parameters": [
///         // metadata.parameters에서 자동 생성
///       ],
///       "responses": {
///         "200": {
///           "description": "Success",
///           "content": {
///             "application/json": {
///               "schema": {
///                 "$ref": "#/components/schemas/\(metadata.responseTypeName)"
///               }
///             }
///           }
///         }
///       }
///     }
///   }
/// }
/// """
/// ```
///
/// ### 3. API 문서 자동화
///
/// 런타임에 메타데이터를 사용한 동적 문서 생성:
///
/// ```swift
/// // 모든 DocumentableAPIRequest 수집
/// let documentableRequests: [any DocumentableAPIRequest.Type] = [
///     GetAllPostsRequest.self,
///     CreatePostRequest.self,
///     // ...
/// ]
///
/// // 태그별로 그룹화
/// let groupedByTag = Dictionary(grouping: documentableRequests) { requestType in
///     requestType.metadata.tags.first ?? "Uncategorized"
/// }
///
/// // HTML 문서 생성
/// for (tag, requests) in groupedByTag {
///     print("<h2>\(tag)</h2>")
///     for request in requests {
///         let meta = request.metadata
///         print("""
///         <div class="endpoint">
///             <h3>\(meta.title)</h3>
///             <p><code>\(meta.method) \(meta.path)</code></p>
///             <p>\(meta.description)</p>
///         </div>
///         """)
///     }
/// }
/// ```
///
/// ## 관련 프로토콜 및 타입
///
/// ### DocumentableAPIRequest
///
/// `@APIDocument`가 자동으로 채택하는 프로토콜:
///
/// ```swift
/// public protocol DocumentableAPIRequest: APIRequest {
///     static var metadata: EndpointMetadata { get }
/// }
/// ```
///
/// ### EndpointMetadata
///
/// 생성되는 메타데이터의 구조:
///
/// ```swift
/// public struct EndpointMetadata {
///     public let id: String                    // Request 타입 이름
///     public let title: String                 // @APIDocument의 title
///     public let description: String           // @APIDocument의 description
///     public let method: String                // HTTP 메서드 (대문자)
///     public let path: String                  // API 경로
///     public let baseURLString: String         // 베이스 URL
///     public let headers: [String: String]     // 기본 헤더
///     public let tags: [String]                // @APIDocument의 tags
///     public let parameters: [String]          // 파라미터 이름 목록
///     public let responseTypeName: String      // 응답 타입 이름
/// }
/// ```
///
/// ## 모범 사례
///
/// ### 1. 일관된 태그 사용
///
/// ```swift
/// // 좋은 예: 명확한 계층 구조
/// tags: ["Users", "CRUD", "Admin"]
/// tags: ["Posts", "Read", "Public"]
/// tags: ["Auth", "Security"]
///
/// // 피할 예: 일관성 없는 네이밍
/// tags: ["user", "Users", "USER"]  // 대소문자 혼용
/// tags: ["get", "read", "fetch"]   // 동일 의미의 다양한 표현
/// ```
///
/// ### 2. 구조화된 설명 작성
///
/// ```swift
/// description: """
/// [한 줄 요약]
///
/// ## 상세 설명
/// [자세한 설명]
///
/// ## 권한 요구사항
/// - 인증: 필요/불필요
/// - 권한: 필요한 권한 목록
///
/// ## 쿼리 파라미터
/// - `page`: 페이지 번호 (기본값: 1)
/// - `limit`: 페이지당 아이템 수 (기본값: 20)
///
/// ## 응답 예시
/// [응답 데이터 예시 또는 설명]
/// """
/// ```
///
/// ### 3. 의미 있는 제목 작성
///
/// ```swift
/// // 좋은 예: 동사 + 명사 형태
/// title: "Get user profile"
/// title: "Create new post"
/// title: "Update user settings"
/// title: "Delete comment"
///
/// // 피할 예: 불명확한 제목
/// title: "User"           // 무슨 동작인지 불명확
/// title: "API"            // 너무 일반적
/// title: "GetUserById"    // 함수명 그대로 (소문자 시작 권장)
/// ```
///
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
