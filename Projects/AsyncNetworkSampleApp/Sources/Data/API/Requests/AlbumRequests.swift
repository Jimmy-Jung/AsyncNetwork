//
//  AlbumRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/12 - Migrated to separated macros
//

import AsyncNetwork
import Foundation

// MARK: - Error Response Models

struct AlbumNotFoundError: Codable, Sendable, Error {
    let error: String
    let code: String
}

struct PhotoNotFoundError: Codable, Sendable, Error {
    let error: String
    let code: String
}

// MARK: - Get Albums for User

@APIRequest(
    response: [AlbumDTO].self,
    baseURL: jsonPlaceholderURL,
    path: "/albums",
    method: .get
)
struct GetAlbumsForUserRequest {
    @QueryParameter var userId: Int
    @QueryParameter(key: "_limit") var limit: Int?

    init(userId: Int, limit: Int? = nil) {
        self.userId = userId
        self.limit = limit
    }
}

extension GetAlbumsForUserRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetAlbumsForUserRequest",
            title: "Get Albums for User",
            description: "특정 사용자의 앨범 목록을 조회합니다.",
            method: "GET",
            path: "/albums",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Albums"],
            parameters: ["userId", "limit"],
            responseTypeName: "[AlbumDTO]"
        )
    }
}

// MARK: - Get Album by ID

@APIRequest(
    response: AlbumDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/albums/{id}",
    method: .get,
    errorResponses: [
        404: AlbumNotFoundError.self
    ]
)
struct GetAlbumByIdRequest {
    @PathParameter var id: Int
}

extension GetAlbumByIdRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetAlbumByIdRequest",
            title: "Get Album by ID",
            description: "특정 앨범을 ID로 조회합니다.",
            method: "GET",
            path: "/albums/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Albums"],
            parameters: ["id"],
            responseTypeName: "AlbumDTO"
        )
    }
}

// MARK: - Get Photos for Album

@APIRequest(
    response: [PhotoDTO].self,
    baseURL: jsonPlaceholderURL,
    path: "/photos",
    method: .get
)
struct GetPhotosForAlbumRequest {
    @QueryParameter(key: "albumId") var albumId: Int
    @QueryParameter(key: "_limit") var limit: Int?

    init(albumId: Int, limit: Int? = nil) {
        self.albumId = albumId
        self.limit = limit
    }
}

extension GetPhotosForAlbumRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetPhotosForAlbumRequest",
            title: "Get Photos for Album",
            description: "특정 앨범의 사진 목록을 조회합니다.",
            method: "GET",
            path: "/photos",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Photos"],
            parameters: ["albumId", "limit"],
            responseTypeName: "[PhotoDTO]"
        )
    }
}

// MARK: - Get Photo by ID

@APIRequest(
    response: PhotoDTO.self,
    baseURL: jsonPlaceholderURL,
    path: "/photos/{id}",
    method: .get,
    errorResponses: [
        404: PhotoNotFoundError.self
    ]
)
struct GetPhotoByIdRequest {
    @PathParameter var id: Int
}

extension GetPhotoByIdRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetPhotoByIdRequest",
            title: "Get Photo by ID",
            description: "특정 사진을 ID로 조회합니다.",
            method: "GET",
            path: "/photos/{id}",
            baseURLString: jsonPlaceholderURL,
            headers: [:],
            tags: ["Photos"],
            parameters: ["id"],
            responseTypeName: "PhotoDTO"
        )
    }
}
