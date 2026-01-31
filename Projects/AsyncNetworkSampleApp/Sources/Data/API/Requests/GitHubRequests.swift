//
//  GitHubRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//  Updated: 2026/01/12 - Migrated to separated macros
//

import AsyncNetwork
import Foundation

let gitHubBaseURL = "https://api.github.com"

// MARK: - Get GitHub User

/// GitHub 사용자 정보 조회
///
/// **참고**: GitHub API는 인증 없이 시간당 60회 제한이 있습니다.
@APIRequest(
    response: GitHubUserDTO.self,
    baseURL: gitHubBaseURL,
    path: "/users/{username}",
    method: .get
)
struct GetGitHubUserRequest {
    @PathParameter var username: String
}

extension GetGitHubUserRequest: DocumentableRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetGitHubUserRequest",
            title: "Get GitHub User",
            description: "GitHub 사용자 정보를 조회합니다. (인증 없이 시간당 60회 제한)",
            method: "GET",
            path: "/users/{username}",
            baseURLString: gitHubBaseURL,
            headers: [:],
            tags: ["GitHub"],
            parameters: ["username"],
            responseTypeName: "GitHubUserDTO"
        )
    }
}
