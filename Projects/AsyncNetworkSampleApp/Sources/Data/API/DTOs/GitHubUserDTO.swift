//
//  GitHubUserDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetworkMacros
import Foundation

/// GitHub User DTO (ETag 캐싱 데모용)
///
/// GitHub API는 ETag를 완벽하게 지원합니다:
/// - 첫 요청: 200 OK + ETag 헤더
/// - 두 번째 요청 (If-None-Match): 304 Not Modified
@Response(
    mockStrategy: .random,
    fixtureJSON: """
    {
      "login": "octocat",
      "id": 1,
      "avatar_url": "https://avatars.githubusercontent.com/u/583231",
      "name": "The Octocat",
      "company": "@github",
      "blog": "https://github.blog",
      "location": "San Francisco",
      "email": "octocat@github.com",
      "bio": "GitHub mascot",
      "public_repos": 8,
      "public_gists": 8,
      "followers": 9999,
      "following": 9,
      "created_at": "2008-01-14T04:33:35Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 1
)
struct GitHubUserDTO: Codable, Sendable {
    let login: String
    let id: Int
    let avatarUrl: String
    let name: String?
    let company: String?
    let blog: String?
    let location: String?
    let email: String?
    let bio: String?
    let publicRepos: Int
    let publicGists: Int
    let followers: Int
    let following: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case login, id, name, company, blog, location, email, bio, followers, following
        case avatarUrl = "avatar_url"
        case publicRepos = "public_repos"
        case publicGists = "public_gists"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
