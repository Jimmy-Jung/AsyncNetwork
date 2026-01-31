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
