//
//  APIRequestCatalog.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//  Updated: 2026/01/12 - Added all 17 requests
//

import AsyncNetwork
import Foundation

/// 앱의 모든 API 요청 카탈로그
enum APIRequestCatalog {
    /// 모든 API Request의 메타데이터
    static let all: [EndpointMetadata] = [
        // Posts (6개)
        GetAllPostsRequest.metadata,
        GetPostByIdRequest.metadata,
        CreatePostRequest.metadata,
        UpdatePostRequest.metadata,
        PatchPostRequest.metadata,
        DeletePostRequest.metadata,
        
        // Users (3개)
        GetAllUsersRequest.metadata,
        GetUserByIdRequest.metadata,
        CreateUserRequest.metadata,
        
        // Albums (2개)
        GetAlbumsForUserRequest.metadata,
        GetAlbumByIdRequest.metadata,
        
        // Photos (2개)
        GetPhotosForAlbumRequest.metadata,
        GetPhotoByIdRequest.metadata,
        
        // Comments (3개)
        GetCommentsForPostRequest.metadata,
        GetCommentByIdRequest.metadata,
        CreateCommentRequest.metadata,
        
        // GitHub (1개)
        GetGitHubUserRequest.metadata,
    ]
}
