//
//  APIRequests.swift
//  OpenAPIExample
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/14 - Migrated to separated macros
//

import AsyncNetwork
import Foundation

// MARK: - Base URLs

let jsonPlaceholderURL = "https://jsonplaceholder.typicode.com"
let apiExampleURL = "https://api.example.com"

// MARK: - Posts API

@APIRequest(
    response: [Post].self,
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .get
)
@APIDocument(
    title: "Get all posts",
    description: """
    JSONPlaceholder에서 모든 포스트를 가져옵니다.
    
    기능:
    • 페이지네이션 지원 (_limit 파라미터)
    • 사용자별 필터링 (userId 파라미터)
    
    응답 형식:
    Post 객체의 배열을 반환합니다.
    """,
    tags: ["Posts"]
)
@APITestable(
    scenarios: [.success, .serverError, .timeout],
    errorExamples: [
        "500": """
        {
          "error": "Internal Server Error",
          "message": "Failed to fetch posts"
        }
        """
    ]
)
struct GetAllPostsRequest {
    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
    
    init(userId: Int? = nil, limit: Int? = nil) {
        self.userId = userId
        self.limit = limit
    }
}

@APIRequest(
    response: Post.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Get post by ID",
    description: """
    특정 포스트의 상세 정보를 가져옵니다.
    
    파라미터:
    • id: Post의 고유 식별자
    
    헤더:
    • User-Agent: 클라이언트 정보
    • Accept-Language: 선호 언어 설정
    
    에러 처리:
    • 404: 포스트를 찾을 수 없음
    • 500: 서버 내부 오류
    """,
    tags: ["Posts"]
)
@APITestable(
    scenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """,
        "500": """
        {
          "error": "Internal server error"
        }
        """
    ]
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetwork/2.0.0"
    @HeaderField(key: .acceptLanguage) var acceptLanguage: String? = "ko-KR,ko;q=0.9,en;q=0.8"
    
    init(id: Int, userAgent: String? = "AsyncNetwork/2.0.0", acceptLanguage: String? = "ko-KR,ko;q=0.9,en;q=0.8") {
        self.id = id
        self.userAgent = userAgent
        self.acceptLanguage = acceptLanguage
    }
}

@APIRequest(
    response: Post.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .post,
    errorResponses: [
        400: BadRequestError.self
    ]
)
@APIDocument(
    title: "Create a new post",
    description: """
    새로운 포스트를 생성합니다.
    
    요청 바디:
    • title: 포스트 제목 (필수)
    • body: 포스트 본문 (필수)
    • userId: 작성자 ID (필수)
    
    검증 규칙:
    • title: 1-200자
    • body: 1-5000자
    • userId: 양의 정수
    """,
    tags: ["Posts"]
)
@APITestable(
    scenarios: [.success, .clientError, .serverError],
    errorExamples: [
        "400": """
        {
          "error": "Invalid request body",
          "code": "BAD_REQUEST"
        }
        """,
        "500": """
        {
          "error": "Internal server error"
        }
        """
    ]
)
struct CreatePostRequest {
    @RequestBody var body: PostBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
    
    init(body: PostBody? = nil, contentType: String? = "application/json", requestId: String? = UUID().uuidString) {
        self.body = body
        self.contentType = contentType
        self.requestId = requestId
    }
}

@APIRequest(
    response: Post.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .put,
    errorResponses: [
        404: NotFoundError.self,
        400: BadRequestError.self
    ]
)
@APIDocument(
    title: "Update a post",
    description: """
    기존 포스트를 업데이트합니다.
    
    동작 방식:
    • PUT: 전체 리소스 교체
    • 모든 필드가 요청 바디에 포함되어야 함
    
    파라미터:
    • id: 업데이트할 Post의 ID
    
    에러 처리:
    • 404: 포스트를 찾을 수 없음
    • 400: 잘못된 요청 데이터
    """,
    tags: ["Posts"]
)
@APITestable(
    scenarios: [.success, .notFound, .clientError],
    errorExamples: [
        "404": """
        {
          "error": "Post not found"
        }
        """,
        "400": """
        {
          "error": "Invalid request body"
        }
        """
    ]
)
struct UpdatePostRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(id: Int, body: PostBody? = nil, contentType: String? = "application/json") {
        self.id = id
        self.body = body
        self.contentType = contentType
    }
}

@APIRequest(
    response: EmptyResponse.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .delete,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Delete a post",
    description: """
    특정 ID를 가진 포스트를 삭제합니다.
    
    파라미터:
    • id: 삭제할 Post의 ID
    
    응답:
    성공 시 빈 응답 반환 (204 No Content)
    
    에러 처리:
    • 404: 포스트를 찾을 수 없음
    • 403: 삭제 권한 없음
    """,
    tags: ["Posts"]
)
@APITestable(
    scenarios: [.success, .notFound, .unauthorized],
    errorExamples: [
        "404": """
        {
          "error": "Post not found"
        }
        """,
        "403": """
        {
          "error": "Forbidden",
          "code": "FORBIDDEN"
        }
        """
    ]
)
struct DeletePostRequest {
    @PathParameter var id: Int
    
    init(id: Int) {
        self.id = id
    }
}

// MARK: - Users API

@APIRequest(
    response: [User].self,
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .get,
    errorResponses: [
        500: ServerError.self
    ]
)
@APIDocument(
    title: "Get all users",
    description: """
    모든 사용자 목록을 가져옵니다.
    
    기능:
    • 완전한 사용자 프로필 정보 포함
    • 주소, 회사, 연락처 정보 포함
    
    응답 형식:
    User 객체의 배열을 반환합니다.
    """,
    tags: ["Users"]
)
@APITestable(
    scenarios: [.success, .serverError],
    errorExamples: [
        "500": """
        {
          "error": "Internal server error",
          "code": "INTERNAL_ERROR",
          "timestamp": "2026-01-14T10:30:00Z",
          "requestId": "req-12345"
        }
        """
    ]
)
struct GetAllUsersRequest {
    init() {}
}

@APIRequest(
    response: User.self,
    baseURL: jsonPlaceholderURL,
    path: "/users/{id}",
    method: .get,
    errorResponses: [
        404: NotFoundError.self,
        500: ServerError.self
    ]
)
@APIDocument(
    title: "Get user by ID",
    description: """
    특정 사용자의 상세 정보를 가져옵니다.
    
    파라미터:
    • id: User의 고유 식별자
    
    커스텀 헤더:
    • X-Client-Version: 클라이언트 버전 정보
    • X-Platform: 플랫폼 정보 (iOS/Android/Web)
    
    응답:
    완전한 사용자 프로필 정보 (주소, 회사, 연락처 포함)
    
    에러 처리:
    • 404: 사용자를 찾을 수 없음
    • 500: 서버 내부 오류
    """,
    tags: ["Users"]
)
@APITestable(
    scenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """
        {
          "error": "User not found",
          "code": "USER_NOT_FOUND"
        }
        """
    ]
)
struct GetUserByIdRequest {
    @PathParameter var id: Int
    @CustomHeader("X-Client-Version") var clientVersion: String? = "1.0.0"
    @CustomHeader("X-Platform") var platform: String? = "iOS"
    
    init(id: Int, clientVersion: String? = "1.0.0", platform: String? = "iOS") {
        self.id = id
        self.clientVersion = clientVersion
        self.platform = platform
    }
}

@APIRequest(
    response: User.self,
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .post,
    errorResponses: [
        400: BadRequestError.self
    ]
)
@APIDocument(
    title: "Create a new user",
    description: """
    새로운 사용자를 생성합니다.
    
    요청 바디:
    • name: 사용자 이름 (필수)
    • username: 사용자명 (필수, 고유)
    • email: 이메일 주소 (필수, 유효한 형식)
    
    검증 규칙:
    • name: 1-100자
    • username: 3-20자, 영문/숫자만
    • email: 유효한 이메일 형식
    
    에러 처리:
    • 400: 잘못된 요청 데이터
    • 409: 이미 존재하는 username 또는 email
    """,
    tags: ["Users"]
)
@APITestable(
    scenarios: [.success, .clientError],
    errorExamples: [
        "400": """
        {
          "error": "Invalid user data"
        }
        """,
        "409": """
        {
          "error": "User already exists",
          "code": "CONFLICT"
        }
        """
    ]
)
struct CreateUserRequest {
    @RequestBody var body: UserBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .timestamp) var timestamp: String? = String(Int(Date().timeIntervalSince1970))
    
    init(body: UserBody? = nil, authorization: String? = nil, timestamp: String? = String(Int(Date().timeIntervalSince1970))) {
        self.body = body
        self.authorization = authorization
        self.timestamp = timestamp
    }
}

// MARK: - Comments API

@APIRequest(
    response: [Comment].self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{postId}/comments",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Get post comments",
    description: """
    특정 포스트의 모든 댓글을 가져옵니다.
    
    파라미터:
    • postId: 댓글을 조회할 Post의 ID
    
    응답 형식:
    Comment 객체의 배열을 반환합니다.
    
    에러 처리:
    • 404: 포스트를 찾을 수 없음
    """,
    tags: ["Comments"]
)
@APITestable(
    scenarios: [.success, .notFound],
    errorExamples: [
        "404": """
        {
          "error": "Post not found"
        }
        """
    ]
)
struct GetPostCommentsRequest {
    @PathParameter var postId: Int
    
    init(postId: Int) {
        self.postId = postId
    }
}

@APIRequest(
    response: Comment.self,
    baseURL: jsonPlaceholderURL,
    path: "/comments",
    method: .post,
    errorResponses: [
        400: BadRequestError.self
    ]
)
@APIDocument(
    title: "Create a comment",
    description: """
    새로운 댓글을 작성합니다.
    
    요청 바디:
    • postId: 댓글을 작성할 Post의 ID (필수)
    • name: 댓글 제목 (필수)
    • email: 작성자 이메일 (필수)
    • body: 댓글 내용 (필수)
    
    검증 규칙:
    • postId: 양의 정수
    • email: 유효한 이메일 형식
    • body: 1-1000자
    """,
    tags: ["Comments"]
)
@APITestable(
    scenarios: [.success, .clientError],
    errorExamples: [
        "400": """
        {
          "error": "Invalid comment data"
        }
        """
    ]
)
struct CreateCommentRequest {
    @RequestBody var body: CommentBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(body: CommentBody? = nil, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

// MARK: - Albums API

@APIRequest(
    response: [Album].self,
    baseURL: jsonPlaceholderURL,
    path: "/users/{userId}/albums",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Get user albums",
    description: """
    특정 사용자의 모든 앨범을 가져옵니다.
    
    파라미터:
    • userId: 앨범을 조회할 User의 ID
    
    응답 형식:
    Album 객체의 배열을 반환합니다.
    
    에러 처리:
    • 404: 사용자를 찾을 수 없음
    """,
    tags: ["Albums"]
)
@APITestable(
    scenarios: [.success, .notFound],
    errorExamples: [
        "404": """
        {
          "error": "User not found"
        }
        """
    ]
)
struct GetUserAlbumsRequest {
    @PathParameter var userId: Int
    
    init(userId: Int) {
        self.userId = userId
    }
}

@APIRequest(
    response: [Photo].self,
    baseURL: jsonPlaceholderURL,
    path: "/albums/{albumId}/photos",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Get album photos",
    description: """
    특정 앨범의 모든 사진을 가져옵니다.
    
    파라미터:
    • albumId: 사진을 조회할 Album의 ID
    
    응답 형식:
    Photo 객체의 배열을 반환합니다. 각 Photo는 썸네일과 원본 이미지 URL을 포함합니다.
    
    에러 처리:
    • 404: 앨범을 찾을 수 없음
    """,
    tags: ["Albums"]
)
@APITestable(
    scenarios: [.success, .notFound],
    errorExamples: [
        "404": """
        {
          "error": "Album not found"
        }
        """
    ]
)
struct GetAlbumPhotosRequest {
    @PathParameter var albumId: Int
    
    init(albumId: Int) {
        self.albumId = albumId
    }
}

// MARK: - Complex Order API

@APIRequest(
    response: Order.self,
    baseURL: apiExampleURL,
    path: "/orders",
    method: .post,
    errorResponses: [
        400: BadRequestError.self
    ]
)
@APIDocument(
    title: "Create an order",
    description: """
    복잡한 주문을 생성합니다.
    
    요청 바디:
    • items: 주문 항목 배열 (필수)
    • shippingAddress: 배송지 정보 (필수)
    • paymentMethod: 결제 수단 정보 (필수)
    • couponCode: 쿠폰 코드 (선택)
    • giftMessage: 선물 메시지 (선택)
    • subscribeNewsletter: 뉴스레터 구독 여부
    
    특징:
    • X-Idempotency-Key 헤더로 중복 요청 방지
    • Request-Id로 요청 추적
    • Session-Id로 사용자 세션 추적
    
    검증:
    • items는 1개 이상 포함되어야 함
    • shippingAddress의 모든 필수 필드 검증
    • paymentMethod 유효성 검증
    
    에러 처리:
    • 400: 잘못된 주문 데이터
    • 402: 결제 실패
    • 422: 재고 부족
    """,
    tags: ["Orders"]
)
@APITestable(
    scenarios: [.success, .clientError],
    errorExamples: [
        "400": """
        {
          "error": "Invalid order data",
          "details": ["Missing shipping address"]
        }
        """,
        "402": """
        {
          "error": "Payment required",
          "code": "PAYMENT_FAILED"
        }
        """,
        "422": """
        {
          "error": "Out of stock",
          "productId": 101
        }
        """
    ]
)
struct CreateOrderRequest {
    @RequestBody var body: CreateOrderBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
    @HeaderField(key: .sessionId) var sessionId: String?
    @CustomHeader("X-Idempotency-Key") var idempotencyKey: String? = UUID().uuidString
    
    init(
        body: CreateOrderBody? = nil,
        authorization: String? = nil,
        requestId: String? = UUID().uuidString,
        sessionId: String? = nil,
        idempotencyKey: String? = UUID().uuidString
    ) {
        self.body = body
        self.authorization = authorization
        self.requestId = requestId
        self.sessionId = sessionId
        self.idempotencyKey = idempotencyKey
    }
}

@APIRequest(
    response: Order.self,
    baseURL: apiExampleURL,
    path: "/orders/{orderId}",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Get order by ID",
    description: """
    특정 주문의 상세 정보를 조회합니다.
    
    파라미터:
    • orderId: 조회할 Order의 ID
    
    헤더:
    • Authorization: 인증 토큰 (필수)
    • User-Agent: 클라이언트 정보
    
    응답:
    완전한 주문 정보 (주문 항목, 배송지, 결제 정보, 배송 예정일 포함)
    
    에러 처리:
    • 404: 주문을 찾을 수 없음
    • 403: 접근 권한 없음
    """,
    tags: ["Orders"]
)
@APITestable(
    scenarios: [.success, .notFound, .unauthorized],
    errorExamples: [
        "404": """
        {
          "error": "Order not found",
          "orderId": 9001
        }
        """,
        "403": """
        {
          "error": "Access denied",
          "code": "FORBIDDEN"
        }
        """
    ]
)
struct GetOrderRequest {
    @PathParameter var orderId: Int
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetwork/2.0.0"
    
    init(orderId: Int, authorization: String? = nil, userAgent: String? = "AsyncNetwork/2.0.0") {
        self.orderId = orderId
        self.authorization = authorization
        self.userAgent = userAgent
    }
}
