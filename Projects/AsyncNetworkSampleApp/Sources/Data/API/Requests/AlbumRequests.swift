//
//  AlbumRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncNetworkMacros
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
    title: "Get albums for a user",
    description: """
    특정 사용자의 모든 앨범을 가져옵니다.
    
    파라미터:
    • userId: 앨범을 조회할 User의 ID (필수)
    
    기능:
    • userId 기준 필터링
    • 페이지네이션 지원
    
    응답 형식:
    Album 객체의 배열을 반환합니다.
    """,
    baseURL: jsonPlaceholderURL,
    path: "/albums",
    method: .get,
    tags: ["Albums"],
    testScenarios: [.success, .clientError, .serverError, .timeout],
    errorExamples: [
        "400": """
        {
          "error": "Bad Request",
          "message": "userId parameter is required"
        }
        """,
        "500": """
        {
          "error": "Internal Server Error",
          "message": "Failed to fetch albums"
        }
        """
    ],
    includeRetryTests: true,
    includePerformanceTests: true
)
struct GetAlbumsForUserRequest {
    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
}

// MARK: - Get Album by ID

@APIRequest(
    response: AlbumDTO.self,
    title: "Get an album by ID",
    description: """
    특정 ID를 가진 앨범을 가져옵니다.
    
    파라미터:
    • id: Album의 고유 식별자
    
    에러 처리:
    • 404: 앨범을 찾을 수 없음
    """,
    baseURL: jsonPlaceholderURL,
    path: "/albums/{id}",
    method: .get,
    tags: ["Albums"],
    errorResponses: [
        404: AlbumNotFoundError.self
    ],
    testScenarios: [.success, .notFound],
    errorExamples: [
        "404": """
        {
          "error": "Album not found",
          "code": "ALBUM_NOT_FOUND"
        }
        """
    ],
    includeRetryTests: true
)
struct GetAlbumByIdRequest {
    @PathParameter var id: Int
}

// MARK: - Get Photos for Album

@APIRequest(
    response: [PhotoDTO].self,
    title: "Get photos for an album",
    description: """
    특정 앨범의 모든 사진을 가져옵니다.
    
    파라미터:
    • albumId: 사진을 조회할 Album의 ID (필수)
    
    기능:
    • albumId 기준 필터링
    • 페이지네이션 지원
    • 썸네일 URL 포함
    
    응답 형식:
    Photo 객체의 배열을 반환합니다. 각 객체는 원본 이미지 URL과 썸네일 URL을 포함합니다.
    """,
    baseURL: jsonPlaceholderURL,
    path: "/photos",
    method: .get,
    tags: ["Photos"],
    testScenarios: [.success, .clientError, .serverError, .timeout],
    errorExamples: [
        "400": """
        {
          "error": "Bad Request",
          "message": "albumId parameter is required"
        }
        """,
        "500": """
        {
          "error": "Internal Server Error",
          "message": "Failed to fetch photos"
        }
        """
    ],
    includeRetryTests: true,
    includePerformanceTests: true
)
struct GetPhotosForAlbumRequest {
    @QueryParameter(key: "albumId") var albumId: Int?
    @QueryParameter(key: "_limit") var limit: Int?
}

// MARK: - Get Photo by ID

@APIRequest(
    response: PhotoDTO.self,
    title: "Get a photo by ID",
    description: """
    특정 ID를 가진 사진을 가져옵니다.
    
    파라미터:
    • id: Photo의 고유 식별자
    
    응답:
    원본 이미지 URL과 썸네일 URL을 포함한 Photo 객체
    
    에러 처리:
    • 404: 사진을 찾을 수 없음
    """,
    baseURL: jsonPlaceholderURL,
    path: "/photos/{id}",
    method: .get,
    tags: ["Photos"],
    errorResponses: [
        404: PhotoNotFoundError.self
    ],
    testScenarios: [.success, .notFound],
    errorExamples: [
        "404": """
        {
          "error": "Photo not found",
          "code": "PHOTO_NOT_FOUND"
        }
        """
    ],
    includeRetryTests: true
)
struct GetPhotoByIdRequest {
    @PathParameter var id: Int
}
