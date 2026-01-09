//
//  PostRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncNetworkMacros
import Foundation

let jsonPlaceholderURL = "https://jsonplaceholder.typicode.com"

// MARK: - Error Response Models

struct PostNotFoundError: Codable, Sendable, Error {
    let error: String
    let code: String
}

struct BadRequestError: Codable, Sendable, Error {
    let error: String
    let message: String
}

// MARK: - Get All Posts

@APIRequest(
    response: [PostDTO].self,
    title: "Get all posts",
    description: """
    JSONPlaceholder에서 모든 포스트를 가져옵니다.
    
    ## 기능
    - 페이지네이션 지원 (_limit 파라미터)
    - 사용자별 필터링 (userId 파라미터)
    
    ## 응답 형식
    Post 객체의 배열을 반환합니다.
    """,
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .get,
    tags: ["Posts"],
    testScenarios: [.success, .serverError, .networkError, .timeout],
    errorExamples: [
        "500": """
        {
          "error": "Internal Server Error",
          "message": "Failed to fetch posts"
        }
        """,
        "503": """
        {
          "error": "Service Unavailable",
          "message": "Database connection failed"
        }
        """
    ],
    includeRetryTests: true,
    includePerformanceTests: true
)
struct GetAllPostsRequest {
    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
    @QueryParameter(key: "_page") var page: Int?
}

// MARK: - Get Post by ID

@APIRequest(
    response: PostDTO.self,
    title: "Get a post by ID",
    description: """
    특정 ID를 가진 포스트를 가져옵니다.
    
    ## 파라미터
    - id: Post의 고유 식별자
    
    ## 에러 처리
    - 404: 포스트를 찾을 수 없음
    - 500: 서버 내부 오류
    """,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .get,
    tags: ["Posts"],
    errorResponses: [
        404: PostNotFoundError.self
    ],
    testScenarios: [.success, .notFound, .serverError, .invalidResponse],
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """,
        "400": """
        {
          "error": "Bad Request",
          "message": "Invalid post ID format"
        }
        """
    ],
    includeRetryTests: true
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
    
    var path: String {
        "/posts/\(id)"
    }
}

// MARK: - Create Post

@APIRequest(
    response: PostDTO.self,
    title: "Create a new post",
    description: """
    새로운 포스트를 생성합니다.
    
    ## 요청 바디
    - title: 포스트 제목 (필수)
    - body: 포스트 본문 (필수)
    - userId: 작성자 ID (필수)
    
    ## 검증 규칙
    - title: 1-200자
    - body: 1-5000자
    - userId: 양의 정수
    """,
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .post,
    tags: ["Posts"],
    errorResponses: [
        400: BadRequestError.self,
        401: PostNotFoundError.self
    ],
    testScenarios: [.success, .clientError, .unauthorized, .serverError],
    errorExamples: [
        "400": """
        {
          "error": "Bad Request",
          "message": "Title and body are required"
        }
        """,
        "401": """
        {
          "error": "Unauthorized",
          "code": "AUTH_REQUIRED"
        }
        """,
        "422": """
        {
          "error": "Validation Failed",
          "message": "Title must be between 1-200 characters"
        }
        """
    ],
    includeRetryTests: false,
    includePerformanceTests: false
)
struct CreatePostRequest {
    @RequestBody var body: PostBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}

// MARK: - Update Post

@APIRequest(
    response: PostDTO.self,
    title: "Update a post",
    description: """
    기존 포스트를 업데이트합니다.
    
    ## 동작 방식
    - PUT: 전체 리소스 교체
    - 모든 필드가 요청 바디에 포함되어야 함
    
    ## 파라미터
    - id: 업데이트할 Post의 ID
    
    ## 에러 처리
    - 404: 포스트를 찾을 수 없음
    - 400: 잘못된 요청 데이터
    """,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .put,
    tags: ["Posts"],
    errorResponses: [
        404: PostNotFoundError.self,
        400: BadRequestError.self
    ],
    testScenarios: [.success, .notFound, .clientError, .serverError],
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """,
        "400": """
        {
          "error": "Bad Request",
          "message": "Invalid request body"
        }
        """
    ],
    includeRetryTests: true
)
struct UpdatePostRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    var path: String {
        "/posts/\(id)"
    }
}

// MARK: - Delete Post

@APIRequest(
    response: EmptyResponse.self,
    title: "Delete a post",
    description: """
    특정 ID를 가진 포스트를 삭제합니다.
    
    ## 파라미터
    - id: 삭제할 Post의 ID
    
    ## 응답
    성공 시 빈 응답 반환 (204 No Content)
    
    ## 에러 처리
    - 404: 포스트를 찾을 수 없음
    - 403: 삭제 권한 없음
    """,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .delete,
    tags: ["Posts"],
    errorResponses: [
        404: PostNotFoundError.self
    ],
    testScenarios: [.success, .notFound, .unauthorized],
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """,
        "403": """
        {
          "error": "Forbidden",
          "message": "You don't have permission to delete this post"
        }
        """
    ],
    includeRetryTests: false
)
struct DeletePostRequest {
    @PathParameter var id: Int
    
    var path: String {
        "/posts/\(id)"
    }
}

// MARK: - Request Body DTO

struct PostBodyDTO: Codable, Sendable {
    let title: String
    let body: String
    let userId: Int
}
