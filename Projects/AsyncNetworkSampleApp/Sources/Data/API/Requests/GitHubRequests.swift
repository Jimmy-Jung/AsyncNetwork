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
@APIDocument(
    title: "Get GitHub User",
    description: """
    GitHub API에서 사용자 정보를 가져옵니다.

    사용 예시:
    • username: "octocat" (GitHub 마스코트)
    • username: "torvalds" (Linux 창시자)
    • username: "gaearon" (React 핵심 개발자)

    참고:
    • GitHub API는 인증 없이 시간당 60회 제한
    """,
    tags: ["GitHub"]
)
@APITestable(
    scenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """
        {
          "message": "Not Found",
          "documentation_url": "https://docs.github.com/rest"
        }
        """,
        "500": """
        {
          "error": "Internal Server Error",
          "message": "GitHub service is unavailable"
        }
        """
    ]
)
struct GetGitHubUserRequest {
    @PathParameter var username: String
}
