//
//  GitHubRepositoryImpl.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import Foundation

/// GitHub API 리포지토리 구현
struct GitHubRepositoryImpl: GitHubRepository {
    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func getUser(username: String) async throws -> GitHubUser {
        let request = GetGitHubUserRequest(username: username)
        let dto = try await networkService.request(request)
        return GitHubUser(dto: dto)
    }
}
