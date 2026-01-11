//
//  GitHubUser.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

/// GitHub 사용자 도메인 모델
struct GitHubUser: Equatable, Sendable {
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
}

// MARK: - Domain Conversion

extension GitHubUser {
    init(dto: GitHubUserDTO) {
        self.init(
            login: dto.login,
            id: dto.id,
            avatarUrl: dto.avatarUrl,
            name: dto.name,
            company: dto.company,
            blog: dto.blog,
            location: dto.location,
            email: dto.email,
            bio: dto.bio,
            publicRepos: dto.publicRepos,
            publicGists: dto.publicGists,
            followers: dto.followers,
            following: dto.following,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }
}
