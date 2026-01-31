//
//  PostRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Migrated to separated macros
//

import AsyncNetwork
import Foundation

let jsonPlaceholderURL: String = "https://jsonplaceholder.typicode.com"

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
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .get
)
struct GetAllPostsRequest {
    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
    @QueryParameter(key: "_page") var page: Int?

    init(userId: Int? = nil, limit: Int? = nil, page: Int? = nil) {
        self.userId = userId
        self.limit = limit
        self.page = page
    }
}

extension GetAllPostsRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetAllPostsRequest",
            title: "Get All Posts",
            description: "모든 게시물을 조회합니다. userId, limit, page 쿼리 파라미터를 지원합니다.",
            method: "GET",
            path: "/posts",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Posts"],
            parameters: ["userId", "limit", "page"],
            responseTypeName: "[PostDTO]"
        )
    }
}

// MARK: - Get Post by ID

@APIRequest(
    response: PostDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .get,
    errorResponses: [
        404: PostNotFoundError.self
    ]
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
}

extension GetPostByIdRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetPostByIdRequest",
            title: "Get Post by ID",
            description: "특정 게시물을 ID로 조회합니다.",
            method: "GET",
            path: "/posts/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Posts"],
            parameters: ["id"],
            responseTypeName: "PostDTO"
        )
    }
}

// MARK: - Create Post

@APIRequest(
    response: PostDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .post,
    errorResponses: [
        400: BadRequestError.self,
        401: PostNotFoundError.self
    ]
)
struct CreatePostRequest {
    @RequestBody var body: PostBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: PostBodyDTO? = nil, contentType: String? = "application/json") {
        self.body = body
        self.contentType = contentType
    }
}

extension CreatePostRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "CreatePostRequest",
            title: "Create Post",
            description: "새로운 게시물을 생성합니다.",
            method: "POST",
            path: "/posts",
            baseURLString: jsonPlaceholderURL,
            headers: ["Content-Type": "application/json"],
            tags: ["Posts"],
            parameters: ["body"],
            responseTypeName: "PostDTO"
        )
    }
}

// MARK: - Update Post

@APIRequest(
    response: PostDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .put,
    errorResponses: [
        404: PostNotFoundError.self,
        400: BadRequestError.self
    ]
)
struct UpdatePostRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBodyDTO?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(id: Int, body: PostBodyDTO? = nil, contentType: String? = "application/json") {
        self.id = id
        self.body = body
        self.contentType = contentType
    }
}

extension UpdatePostRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "UpdatePostRequest",
            title: "Update Post",
            description: "게시물을 전체 수정합니다 (PUT).",
            method: "PUT",
            path: "/posts/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: ["Content-Type": "application/json"],
            tags: ["Posts"],
            parameters: ["id", "body"],
            responseTypeName: "PostDTO"
        )
    }
}

// MARK: - Patch Post

@APIRequest(
    response: PostDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .patch
)
struct PatchPostRequest {
    @PathParameter var id: Int
    @QueryParameter var title: String?

    init(id: Int, title: String? = nil) {
        self.id = id
        self.title = title
    }
}

extension PatchPostRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "PatchPostRequest",
            title: "Patch Post",
            description: "게시물을 부분 수정합니다 (PATCH).",
            method: "PATCH",
            path: "/posts/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Posts"],
            parameters: ["id", "title"],
            responseTypeName: "PostDTO"
        )
    }
}

// MARK: - Delete Post

@APIRequest(
    response: EmptyResponse.self,
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .delete,
    errorResponses: [
        404: PostNotFoundError.self
    ]
)
struct DeletePostRequest {
    @PathParameter var id: Int
}

extension DeletePostRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "DeletePostRequest",
            title: "Delete Post",
            description: "게시물을 삭제합니다.",
            method: "DELETE",
            path: "/posts/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Posts"],
            parameters: ["id"],
            responseTypeName: "EmptyResponse"
        )
    }
}

// MARK: - Request Body DTO

struct PostBodyDTO: Codable, Sendable {
    let title: String
    let body: String
    let userId: Int
}
