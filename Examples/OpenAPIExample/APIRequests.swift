//
//  APIRequests.swift
//  OpenAPIExample
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncNetworkMacros
import Foundation

// MARK: - Base URLs

let jsonPlaceholderURL = "https://jsonplaceholder.typicode.com"
let apiExampleURL = "https://api.example.com"

// MARK: - Posts API

@APIRequest(
    response: [Post].self,
    title: "Get all posts",
    description: "JSONPlaceholder에서 모든 포스트를 가져옵니다. 페이지네이션과 필터링을 지원합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .get,
    tags: ["Posts", "Read"]
)
struct GetAllPostsRequest {
    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
}

@APIRequest(
    response: Post.self,
    title: "Get post by ID",
    description: "특정 포스트의 상세 정보를 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .get,
    tags: ["Posts", "Read"],
    testScenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """{"error": "Post not found", "code": "POST_NOT_FOUND"}""",
        "500": """{"error": "Internal server error"}"""
    ]
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetwork/2.0.0"
    @HeaderField(key: .acceptLanguage) var acceptLanguage: String? = "ko-KR,ko;q=0.9,en;q=0.8"
}

@APIRequest(
    response: Post.self,
    title: "Create a new post",
    description: "새로운 포스트를 생성합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .post,
    tags: ["Posts", "Write"],
    errorExamples: [
        "400": """{"error": "Invalid request body", "code": "BAD_REQUEST"}""",
        "500": """{"error": "Internal server error"}"""
    ]
)
struct CreatePostRequest {
    @RequestBody var body: PostBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
}

@APIRequest(
    response: Post.self,
    title: "Update a post",
    description: "기존 포스트를 업데이트합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .put,
    tags: ["Posts", "Write"],
    errorExamples: [
        "404": """{"error": "Post not found"}""",
        "400": """{"error": "Invalid request body"}"""
    ]
)
struct UpdatePostRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBody?
}

@APIRequest(
    response: EmptyResponse.self,
    title: "Delete a post",
    description: "포스트를 삭제합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .delete,
    tags: ["Posts", "Write"],
    errorExamples: [
        "404": """{"error": "Post not found"}""",
        "403": """{"error": "Forbidden", "code": "FORBIDDEN"}"""
    ]
)
struct DeletePostRequest {
    @PathParameter var id: Int
}

// MARK: - Users API

@APIRequest(
    response: [User].self,
    title: "Get all users",
    description: "모든 사용자 목록을 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .get,
    tags: ["Users", "Read"],
    errorResponses: [
        500: ServerError.self
    ]
)
struct GetAllUsersRequest {}

@APIRequest(
    response: User.self,
    title: "Get user by ID",
    description: "특정 사용자의 상세 정보를 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/users/{id}",
    method: .get,
    tags: ["Users", "Read"],
    errorResponses: [
        404: NotFoundError.self,
        500: ServerError.self
    ],
    errorExamples: [
        "404": """{"error": "User not found", "code": "USER_NOT_FOUND"}"""
    ]
)
struct GetUserByIdRequest {
    @PathParameter var id: Int
    @CustomHeader("X-Client-Version") var clientVersion: String? = "1.0.0"
    @CustomHeader("X-Platform") var platform: String? = "iOS"
}

@APIRequest(
    response: User.self,
    title: "Create a new user",
    description: "새로운 사용자를 생성합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .post,
    tags: ["Users", "Write"],
    errorExamples: [
        "400": """{"error": "Invalid user data"}""",
        "409": """{"error": "User already exists", "code": "CONFLICT"}"""
    ]
)
struct CreateUserRequest {
    @RequestBody var body: UserBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .timestamp) var timestamp: String? = String(Int(Date().timeIntervalSince1970))
}

// MARK: - Comments API

@APIRequest(
    response: [Comment].self,
    title: "Get post comments",
    description: "특정 포스트의 모든 댓글을 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{postId}/comments",
    method: .get,
    tags: ["Comments", "Read"],
    errorExamples: [
        "404": """{"error": "Post not found"}"""
    ]
)
struct GetPostCommentsRequest {
    @PathParameter var postId: Int
}

@APIRequest(
    response: Comment.self,
    title: "Create a comment",
    description: "새로운 댓글을 작성합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/comments",
    method: .post,
    tags: ["Comments", "Write"],
    errorExamples: [
        "400": """{"error": "Invalid comment data"}"""
    ]
)
struct CreateCommentRequest {
    @RequestBody var body: CommentBody?
}

// MARK: - Albums API

@APIRequest(
    response: [Album].self,
    title: "Get user albums",
    description: "특정 사용자의 모든 앨범을 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/users/{userId}/albums",
    method: .get,
    tags: ["Albums", "Read"],
    errorExamples: [
        "404": """{"error": "User not found"}"""
    ]
)
struct GetUserAlbumsRequest {
    @PathParameter var userId: Int
}

@APIRequest(
    response: [Photo].self,
    title: "Get album photos",
    description: "특정 앨범의 모든 사진을 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/albums/{albumId}/photos",
    method: .get,
    tags: ["Albums", "Read"],
    errorExamples: [
        "404": """{"error": "Album not found"}"""
    ]
)
struct GetAlbumPhotosRequest {
    @PathParameter var albumId: Int
}

// MARK: - Complex Order API

@APIRequest(
    response: Order.self,
    title: "Create an order",
    description: "복잡한 주문을 생성합니다. 여러 상품, 배송지, 결제 정보를 포함합니다.",
    baseURL: apiExampleURL,
    path: "/orders",
    method: .post,
    tags: ["Orders", "Write", "Complex"],
    errorExamples: [
        "400": """{"error": "Invalid order data", "details": ["Missing shipping address"]}""",
        "402": """{"error": "Payment required", "code": "PAYMENT_FAILED"}""",
        "422": """{"error": "Out of stock", "productId": 101}"""
    ]
)
struct CreateOrderRequest {
    @RequestBody var body: CreateOrderBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
    @HeaderField(key: .sessionId) var sessionId: String?
    @CustomHeader("X-Idempotency-Key") var idempotencyKey: String? = UUID().uuidString
}

@APIRequest(
    response: Order.self,
    title: "Get order by ID",
    description: "특정 주문의 상세 정보를 조회합니다.",
    baseURL: apiExampleURL,
    path: "/orders/{orderId}",
    method: .get,
    tags: ["Orders", "Read", "Complex"],
    errorExamples: [
        "404": """{"error": "Order not found", "orderId": 9001}""",
        "403": """{"error": "Access denied", "code": "FORBIDDEN"}"""
    ]
)
struct GetOrderRequest {
    @PathParameter var orderId: Int
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetwork/2.0.0"
}
