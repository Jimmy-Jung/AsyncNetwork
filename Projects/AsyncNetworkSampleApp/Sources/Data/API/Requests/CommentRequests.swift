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
struct GetCommentsForPostRequest {
    @QueryParameter var postId: Int
    @QueryParameter(key: "_limit") var limit: Int?

    init(postId: Int, limit: Int? = nil) {
        self.postId = postId
        self.limit = limit
    }
}

extension GetCommentsForPostRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetCommentsForPostRequest",
            title: "Get Comments for Post",
            description: "특정 게시물의 댓글 목록을 조회합니다.",
            method: "GET",
            path: "/comments",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Comments"],
            parameters: ["postId", "limit"],
            responseTypeName: "[CommentDTO]"
        )
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
struct GetCommentByIdRequest {
    @PathParameter var id: Int
}

extension GetCommentByIdRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetCommentByIdRequest",
            title: "Get Comment by ID",
            description: "특정 댓글을 ID로 조회합니다.",
            method: "GET",
            path: "/comments/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Comments"],
            parameters: ["id"],
            responseTypeName: "CommentDTO"
        )
    }
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
struct CreateCommentRequest {
    @RequestBody var body: CommentBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: CommentBodyDTO? = nil, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

extension CreateCommentRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "CreateCommentRequest",
            title: "Create Comment",
            description: "새로운 댓글을 생성합니다.",
            method: "POST",
            path: "/comments",
            baseURLString: jsonPlaceholderURL,
            headers: ["Content-Type": "application/json"],
            tags: ["Comments"],
            parameters: ["body"],
            responseTypeName: "CommentDTO"
        )
    }
}

// MARK: - Request Body DTO

struct CommentBodyDTO: Codable, Sendable {
    let postId: Int
    let name: String
    let email: String
    let body: String
}
