//
//  CommentRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Migrated to separated macros
//

import AsyncNetwork
import Foundation

// MARK: - Error Response Models

struct CommentNotFoundError: Codable, Sendable, Error {
    let error: String
    let code: String
}

struct CommentValidationError: Codable, Sendable, Error {
    let error: String
    let message: String
}

// MARK: - Get Comments for Post

@APIRequest(
    response: [CommentDTO].self,
    baseURL: jsonPlaceholderURL,
    path: "/comments",
    method: .get
)
@APIDocument(
    title: "Get comments for a post",
    description: """
    특정 포스트의 모든 댓글을 가져옵니다.

    파라미터:
    • postId: 댓글을 조회할 Post의 ID (필수)

    기능:
    • postId 기준 필터링
    • 댓글 작성 순서대로 정렬

    응답 형식:
    Comment 객체의 배열을 반환합니다.
    """,
    tags: ["Comments"]
)
@APITestable(
    scenarios: [.success, .clientError, .serverError],
    errorExamples: [
        "400": """
        {
          "error": "Bad Request",
          "message": "postId parameter is required"
        }
        """,
        "500": """
        {
          "error": "Internal Server Error",
          "message": "Failed to fetch comments"
        }
        """
    ]
)
struct GetCommentsForPostRequest {
    @QueryParameter var postId: Int
    @QueryParameter(key: "_limit") var limit: Int?

    init(postId: Int, limit: Int? = nil) {
        self.postId = postId
        self.limit = limit
    }
}

// MARK: - Get Comment by ID

@APIRequest(
    response: CommentDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/comments/{id}",
    method: .get,
    errorResponses: [
        404: CommentNotFoundError.self
    ]
)
@APIDocument(
    title: "Get a comment by ID",
    description: """
    특정 ID를 가진 댓글을 가져옵니다.

    파라미터:
    • id: Comment의 고유 식별자

    에러 처리:
    • 404: 댓글을 찾을 수 없음
    """,
    tags: ["Comments"]
)
@APITestable(
    scenarios: [.success, .notFound],
    errorExamples: [
        "404": """
        {
          "error": "Comment not found",
          "code": "COMMENT_NOT_FOUND"
        }
        """
    ]
)
struct GetCommentByIdRequest {
    @PathParameter var id: Int
}

// MARK: - Create Comment

@APIRequest(
    response: CommentDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/comments",
    method: .post,
    errorResponses: [
        400: CommentValidationError.self,
        404: CommentNotFoundError.self
    ]
)
@APIDocument(
    title: "Create a comment",
    description: """
    새로운 댓글을 생성합니다.

    요청 바디:
    • postId: 댓글을 작성할 포스트 ID (필수)
    • name: 작성자 이름 (필수)
    • email: 작성자 이메일 (필수, 유효한 형식)
    • body: 댓글 내용 (필수)

    검증 규칙:
    • name: 1-100자
    • email: 유효한 이메일 형식
    • body: 1-1000자

    에러 처리:
    • 400: 잘못된 요청 데이터
    • 404: 연관된 포스트를 찾을 수 없음
    • 422: 검증 실패
    """,
    tags: ["Comments"]
)
@APITestable(
    scenarios: [.success, .clientError, .notFound, .serverError],
    errorExamples: [
        "400": """
        {
          "error": "Validation Failed",
          "message": "Invalid comment data"
        }
        """,
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """,
        "422": """
        {
          "error": "Validation Failed",
          "message": "Comment body is too long (max 1000 characters)"
        }
        """
    ]
)
struct CreateCommentRequest {
    @RequestBody var body: CommentBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: CommentBodyDTO? = nil, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

// MARK: - Request Body DTO

struct CommentBodyDTO: Codable, Sendable {
    let postId: Int
    let name: String
    let email: String
    let body: String
}
