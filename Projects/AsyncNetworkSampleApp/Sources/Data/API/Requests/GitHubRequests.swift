//
//  GitHubRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import AsyncNetworkMacros
import Foundation

let gitHubBaseURL = "https://api.github.com"

// MARK: - Get GitHub User

/// GitHub 사용자 정보 조회
///
/// **참고**: GitHub API는 인증 없이 시간당 60회 제한이 있습니다.
@APIRequest(
    response: GitHubUserDTO.self,
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
    baseURL: gitHubBaseURL,
    path: "/users/{username}",
    method: .get,
    tags: ["GitHub"],
    testScenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """
        {
          "message": "Not Found",
          "documentation_url": "https://docs.github.com/rest"
        }
        """,
        "403": """
        {
          "message": "API rate limit exceeded",
          "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
        }
        """,
    ],
    includeRetryTests: false,
    includePerformanceTests: false
)
struct GetGitHubUserRequest {
    @PathParameter var username: String
}
