//
//  APIRequestCatalog.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import Foundation

/// 앱의 모든 API 요청 카탈로그
enum APIRequestCatalog {
    /// 모든 API Request의 메타데이터
    static let all: [EndpointMetadata] = [
        GetAllPostsRequest.metadata,
        GetPostByIdRequest.metadata,
        CreatePostRequest.metadata,
        UpdatePostRequest.metadata,
        PatchPostRequest.metadata,
        DeletePostRequest.metadata,
        GetGitHubUserRequest.metadata,
    ]
}
