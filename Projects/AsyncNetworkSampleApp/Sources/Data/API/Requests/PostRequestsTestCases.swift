//
//  PostRequestsTestCases.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/29.
//  Split from PostRequests.swift for testing required body scenarios
//

import AsyncNetwork
import Foundation

// MARK: - Create Post with Required Body (Test Case)

@APIRequest(
    response: PostDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .post
)
@APIDocument(
    title: "Create a new post with required body",
    description: """
    필수 body를 사용하는 포스트 생성 테스트 케이스입니다.

    특징:
    • body가 Non-optional (필수값)
    • @RequestBody가 필수/옵셔널을 모두 지원하는지 검증

    응답:
    생성된 Post 객체를 반환합니다.
    """,
    tags: ["Posts", "Test"]
)
@APITestable(
    scenarios: [.success, .clientError, .serverError],
    errorExamples: [
        "400": """
        {
          "error": "Bad Request",
          "message": "Missing required field: title"
        }
        """,
        "422": """
        {
          "error": "Validation Failed",
          "message": "Title must be between 1-200 characters"
        }
        """
    ]
)
struct CreatePostWithRequiredBodyRequest {
    @RequestBody var body: PostBodyDTO // 필수 body (Non-optional)
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: PostBodyDTO, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

// MARK: - Update Post with Required Body (Test Case)

@APIRequest(
    response: PostDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .put
)
@APIDocument(
    title: "Update a post with required body",
    description: """
    필수 body를 사용하는 포스트 업데이트 테스트 케이스입니다.

    특징:
    • body가 Non-optional (필수값)
    • PathParameter와 함께 사용

    파라미터:
    • id: 업데이트할 Post의 ID
    """,
    tags: ["Posts", "Test"]
)
@APITestable(
    scenarios: [.success, .notFound, .clientError],
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """
    ]
)
struct UpdatePostWithRequiredBodyRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBodyDTO // 필수 body (Non-optional)
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(id: Int, body: PostBodyDTO, contentType: String? = "application/json") {
        self.id = id
        self.body = body
        self.contentType = contentType
    }
}
