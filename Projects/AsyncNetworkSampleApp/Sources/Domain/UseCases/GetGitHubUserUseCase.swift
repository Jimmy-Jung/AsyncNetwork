//
//  GetGitHubUserUseCase.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

/// GitHub 사용자 정보 조회 UseCase
struct GetGitHubUserUseCase: Sendable {
    private let repository: GitHubRepository

    init(repository: GitHubRepository) {
        self.repository = repository
    }

    /// GitHub 사용자 정보 조회
    ///
    /// ## ETag 캐싱 확인 방법
    /// 1. 동일한 username으로 첫 요청
    ///    → 로그: Request Headers 없음
    ///    → 로그: Response Status 200 OK
    ///    → 로그: Response Headers에 ETag 있음
    ///
    /// 2. 동일한 username으로 재요청
    ///    → 로그: Request Headers에 If-None-Match 있음
    ///    → 로그: Response Status 304 Not Modified
    ///    → 로그: Response Body 없음 (캐시 사용)
    ///
    /// - Parameter username: GitHub 사용자명 (예: "octocat", "torvalds")
    /// - Returns: GitHub 사용자 정보
    func execute(username: String) async throws -> GitHubUser {
        try await repository.getUser(username: username)
    }
}
