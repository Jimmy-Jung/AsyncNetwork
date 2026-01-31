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

@APIRequest@APIDocument    • 사용자별 필터링     
    응답 형식:
    Post 객체의 배열을 반환합니다.
    """,
    tags: ["Posts"]
)
@APITestablestruct GetAllPostsRequest {
    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
    
    init(userId: Int? = nil, limit: Int? = nil) {
        self.userId = userId
        self.limit = limit
    }
}

@APIRequest@APIDocument@APITestablestruct GetPostByIdRequest {
    @PathParameter var id: Int
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetwork/2.0.0"
    @HeaderField(key: .acceptLanguage) var acceptLanguage: String? = "ko-KR,ko;q=0.9,en;q=0.8"
    
    init(id: Int, userAgent: String? = "AsyncNetwork/2.0.0", acceptLanguage: String? = "ko-KR,ko;q=0.9,en;q=0.8") {
        self.id = id
        self.userAgent = userAgent
        self.acceptLanguage = acceptLanguage
    }
}

@APIRequest@APIDocument    • body: 포스트 본문     • userId: 작성자 ID     
    검증 규칙:
    • title: 1-200자
    • body: 1-5000자
    • userId: 양의 정수
    """,
    tags: ["Posts"]
)
@APITestablestruct CreatePostRequest {
    @RequestBody var body: PostBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
    
    init(body: PostBody? = nil, contentType: String? = "application/json", requestId: String? = UUID().uuidString) {
        self.body = body
        self.contentType = contentType
        self.requestId = requestId
    }
}

@APIRequest@APIDocument@APITestablestruct UpdatePostRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(id: Int, body: PostBody? = nil, contentType: String? = "application/json") {
        self.id = id
        self.body = body
        self.contentType = contentType
    }
}

@APIRequest@APIDocument    
    에러 처리:
    • 404: 포스트를 찾을 수 없음
    • 403: 삭제 권한 없음
    """,
    tags: ["Posts"]
)
@APITestablestruct DeletePostRequest {
    @PathParameter var id: Int
    
    init(id: Int) {
        self.id = id
    }
}

// MARK: - Users API

@APIRequest@APIDocument@APITestablestruct GetAllUsersRequest {
    init() {}
}

@APIRequest@APIDocument    
    응답:
    완전한 사용자 프로필 정보     
    에러 처리:
    • 404: 사용자를 찾을 수 없음
    • 500: 서버 내부 오류
    """,
    tags: ["Users"]
)
@APITestablestruct GetUserByIdRequest {
    @PathParameter var id: Int
    @CustomHeader("X-Client-Version") var clientVersion: String? = "1.0.0"
    @CustomHeader("X-Platform") var platform: String? = "iOS"
    
    init(id: Int, clientVersion: String? = "1.0.0", platform: String? = "iOS") {
        self.id = id
        self.clientVersion = clientVersion
        self.platform = platform
    }
}

@APIRequest@APIDocument    • username: 사용자명     • email: 이메일 주소     
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
@APITestablestruct CreateUserRequest {
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

@APIRequest@APIDocument@APITestablestruct GetPostCommentsRequest {
    @PathParameter var postId: Int
    
    init(postId: Int) {
        self.postId = postId
    }
}

@APIRequest@APIDocument    • name: 댓글 제목     • email: 작성자 이메일     • body: 댓글 내용     
    검증 규칙:
    • postId: 양의 정수
    • email: 유효한 이메일 형식
    • body: 1-1000자
    """,
    tags: ["Comments"]
)
@APITestablestruct CreateCommentRequest {
    @RequestBody var body: CommentBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(body: CommentBody? = nil, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

// MARK: - Albums API

@APIRequest@APIDocument@APITestablestruct GetUserAlbumsRequest {
    @PathParameter var userId: Int
    
    init(userId: Int) {
        self.userId = userId
    }
}

@APIRequest@APIDocument@APITestablestruct GetAlbumPhotosRequest {
    @PathParameter var albumId: Int
    
    init(albumId: Int) {
        self.albumId = albumId
    }
}

// MARK: - Complex Order API

@APIRequest@APIDocument    • shippingAddress: 배송지 정보     • paymentMethod: 결제 수단 정보     • couponCode: 쿠폰 코드     • giftMessage: 선물 메시지     • subscribeNewsletter: 뉴스레터 구독 여부
    
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
@APITestablestruct CreateOrderRequest {
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

@APIRequest@APIDocument    • User-Agent: 클라이언트 정보
    
    응답:
    완전한 주문 정보     
    에러 처리:
    • 404: 주문을 찾을 수 없음
    • 403: 접근 권한 없음
    """,
    tags: ["Orders"]
)
@APITestablestruct GetOrderRequest {
    @PathParameter var orderId: Int
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetwork/2.0.0"
    
    init(orderId: Int, authorization: String? = nil, userAgent: String? = "AsyncNetwork/2.0.0") {
        self.orderId = orderId
        self.authorization = authorization
        self.userAgent = userAgent
    }
}
